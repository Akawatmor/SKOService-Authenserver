# SKOService-Authenserver (SAuthenServer)

SAuthenServer is a centralized Authentication and Authorization service designed to secure various internal and external services. It acts as a single source of truth for user identity and access control (RBAC), utilizing Next.js (App Router) and Auth.js.

## 🚀 Features

- **Centralized Authentication**: Single Sign-On (SSO) capabilities for multiple client services.
- **Multiple Providers**: Support for Credentials, Google, GitHub, and Cloudflare Access.
- **RBAC**: Role-Based Access Control management.
- **Modern Stack**: Built with Next.js 14, TypeScript, Tailwind CSS, and Prisma.

## 🛠 Technology Stack

- **Framework:** [Next.js 14](https://nextjs.org/) (App Router)
- **Language:** TypeScript
- **Database:** PostgreSQL
- **ORM:** [Prisma](https://www.prisma.io/)
- **Authentication:** [NextAuth.js / Auth.js](https://next-auth.js.org/)
- **Deployment:** Docker / Proxmox LXC

## 📂 Documentation

- [Architecture Design](docs/architecture-design.md)
- [CI/CD Process](docs/cicd-process.md)
- [Database Schema](docs/database-schema.md)

## 🏁 Getting Started

### Prerequisites

- Node.js (v18+ recommended)
- PostgreSQL Database

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd SKOService-Authenserver
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Environment Setup:**
   
   > **⚠️ Development Note:** 
   > For development, please use the **real environment variables**. You must connect to the database via **OpenVPN**. Connection details and credentials will be provided to **contributors only**.

   Create a `.env` file in the root directory. You will likely need the following variables:
   ```env
   DATABASE_URL="postgresql://user:password@10.x.x.x:5432/skoservice?schema=authenserver_service"
   NEXTAUTH_SECRET="your-secret-key"
   NEXTAUTH_URL="http://localhost:3000"
   ```

4. **Database Setup:**
   Generate the Prisma client:
   ```bash
   npx prisma generate
   ```
   (Optional) Push the schema to the database if you have it running:
   ```bash
   npx prisma db push
   ```

5. **Run the development server:**
   ```bash
   npm run dev
   ```

   Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## 📜 Scripts

- `npm run dev`: Runs the application in development mode.
- `npm run build`: Builds the application for production.
- `npm start`: Starts the production build.
- `npm lint`: Runs ESLint to check for code quality issues.
