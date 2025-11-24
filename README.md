# Supplier Consumer Platform (SCP)

This repository contains the source code for the **Supplier Consumer Platform (SCP)**, a B2B web and mobile application designed to streamline collaboration between food suppliers and institutional consumers (restaurants and hotels).

## Project Structure

- **`backend/`** – Django backend: API logic, business rules, and PostgreSQL database configuration.
- **`mobile/`** – Flutter mobile application for **Sales Representatives** and **Consumers**.
- **`web/my-app/`** – React web frontend for **Owners** and **Managers** (supplier-side web application).


## Prerequisites

Before you begin, ensure the following are installed:

- **Python** and **pip**
- **PostgreSQL**
- **Flutter SDK** and Flutter packages
- **Node.js** and **npm** (for the React web frontend)
- Required Python / Django / Flutter / React packages

## Step 1: Database Configuration

You must create the database and configure the connection settings before running the backend.

1. **Create the Database**

   - Open your PostgreSQL tool (pgAdmin, DBeaver, terminal, etc.).
   - Create a new, empty database for the platform (for example: `scp_db`).

2. **Configure Credentials**

   - Go to the `backend/` directory.
   - Locate the configuration (e.g. `.env` or `settings.py`).
   - Set database connection variables to match your local PostgreSQL setup, for example:

   ```env
   DB_NAME=scp_db          # your database name
   DB_USER=your_username
   DB_PASSWORD=your_password
