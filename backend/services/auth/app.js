const fastify = require("fastify");
const fs = require("fs");
const path = require("path");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// Wait for file to exist with timeout
async function waitForFile(filepath, timeout = 30000) {
  const start = Date.now();
  while (!fs.existsSync(filepath)) {
    if (Date.now() - start > timeout) {
      throw new Error(`Timeout waiting for file: ${filepath}`);
    }
    console.log(`Waiting for ${filepath}...`);
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
}

// Read secret file
async function readSecretFile(filename) {
  const filepath = path.join("/vault/secrets", filename);
  await waitForFile(filepath);
  return fs.readFileSync(filepath, "utf8");
}

// Read JSON secret file
async function readSecretJSON(filename) {
  const content = await readSecretFile(filename);
  return JSON.parse(content);
}

// Mock users database (in real app, this would be a database)
const users = [
  {
    id: 1,
    username: "admin",
    password: bcrypt.hashSync("admin123", 10),
    email: "admin@example.com",
  },
  {
    id: 2,
    username: "user",
    password: bcrypt.hashSync("user123", 10),
    email: "user@example.com",
  },
];

async function startServer() {
  try {
    console.log("Starting auth service...");

    // Read configuration from Vault
    const dbConfig = await readSecretJSON("database.json");
    const authConfig = await readSecretJSON("auth-config.json");

    // Read SSL certificates
    const cert = await readSecretFile("cert.pem");
    const key = await readSecretFile("key.pem");
    const ca = await readSecretFile("ca.pem");

    console.log("✓ Configuration loaded from Vault");
    console.log("✓ SSL certificates loaded");
    console.log("✓ Database config:", {
      host: dbConfig.host,
      username: dbConfig.username,
    });

    // Create HTTPS Fastify server
    const app = fastify({
      https: {
        key: key,
        cert: cert,
        ca: ca,
      },
      logger: {
        level: "info",
      },
    });

    // Register plugins
    await app.register(require("@fastify/cors"), {
      origin: true,
      credentials: true,
    });

    await app.register(require("@fastify/helmet"));

    // Health check endpoint
    app.get("/health", async (request, reply) => {
      return {
        status: "healthy",
        service: "auth-service",
        timestamp: new Date().toISOString(),
        database: {
          host: dbConfig.host,
          port: dbConfig.port,
          database: dbConfig.database,
        },
      };
    });

    // Login endpoint
    app.post("/login", async (request, reply) => {
      const { username, password } = request.body;

      if (!username || !password) {
        return reply.code(400).send({
          error: "Username and password are required",
        });
      }

      const user = users.find((u) => u.username === username);
      if (!user || !bcrypt.compareSync(password, user.password)) {
        return reply.code(401).send({
          error: "Invalid credentials",
        });
      }

      const token = jwt.sign(
        { id: user.id, username: user.username },
        authConfig.jwt_secret,
        { expiresIn: "24h" },
      );

      return {
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
        },
      };
    });

    // Verify token endpoint
    app.post("/verify", async (request, reply) => {
      const { token } = request.body;

      if (!token) {
        return reply.code(400).send({
          error: "Token is required",
        });
      }

      try {
        const decoded = jwt.verify(token, authConfig.jwt_secret);
        const user = users.find((u) => u.id === decoded.id);

        if (!user) {
          return reply.code(401).send({
            error: "User not found",
          });
        }

        return {
          valid: true,
          user: {
            id: user.id,
            username: user.username,
            email: user.email,
          },
        };
      } catch (error) {
        return reply.code(401).send({
          error: "Invalid token",
        });
      }
    });

    // Register endpoint
    app.post("/register", async (request, reply) => {
      const { username, password, email } = request.body;

      if (!username || !password || !email) {
        return reply.code(400).send({
          error: "Username, password, and email are required",
        });
      }

      if (users.find((u) => u.username === username)) {
        return reply.code(409).send({
          error: "Username already exists",
        });
      }

      const newUser = {
        id: users.length + 1,
        username,
        password: bcrypt.hashSync(password, 10),
        email,
      };

      users.push(newUser);

      const token = jwt.sign(
        { id: newUser.id, username: newUser.username },
        authConfig.jwt_secret,
        { expiresIn: "24h" },
      );

      return {
        token,
        user: {
          id: newUser.id,
          username: newUser.username,
          email: newUser.email,
        },
      };
    });

    // Start server
    await app.listen({ port: 3001, host: "0.0.0.0" });
    console.log("✓ Auth service running on https://0.0.0.0:3001");
  } catch (error) {
    console.error("Failed to start auth service:", error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on("SIGTERM", () => {
  console.log("Received SIGTERM, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("Received SIGINT, shutting down gracefully");
  process.exit(0);
});

startServer();
