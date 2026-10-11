# Haitian Dollar (HTD) — MonCash Settlement Service

Bridge gateway connecting the Haitian Dollar mobile wallet, Digicel MonCash Merchant API, and Base L2 smart contract settlement.

## Architecture

```
┌─────────────────┐        ┌────────────────────────┐        ┌─────────────────────────┐
│  Flutter Wallet │───────▶│  HTD Settlement Server │───────▶│  Digicel MonCash API    │
│  (Mobile App)   │◀───────│  (Node.js / Express)   │◀───────│  (Merchant Account)     │
└─────────────────┘        └───────────┬────────────┘        └─────────────────────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │  Base L2 Network    │
                            │  (HTD Smart Token)  │
                            └─────────────────────┘
```

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/health` | `GET` | Service status & MonCash environment |
| `/api/v1/deposits/create` | `POST` | Generates MonCash hosted payment link for user deposit |
| `/api/v1/deposits/:orderId`| `GET` | Polls deposit payment status |
| `/api/v1/deposits/webhook` | `POST` | MonCash IPN webhook for instant confirmation & token mint |
| `/api/v1/withdrawals/create`| `POST` | Burns HTD and initiates MonCash transfer to user phone |

## Local Development & Sandbox Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Enter your Sandbox API credentials from [MonCash Developer Portal](https://sandbox.moncashbutton.digicelgroup.com):
   ```env
   MONCASH_CLIENT_ID=<YOUR_SANDBOX_CLIENT_ID>
   MONCASH_CLIENT_SECRET=<YOUR_SANDBOX_CLIENT_SECRET>
   MONCASH_ENV=sandbox
   PORT=4000
   ```
3. Run the service:
   ```bash
   npm start
   ```

*Note: If credentials are not set, the service automatically runs in high-fidelity simulation mode to allow Flutter client testing without live credentials.*
