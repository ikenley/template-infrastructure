import dotenv from "dotenv"
dotenv.config()
import { handler } from "./src/index.js"

const {
    AWS_REGION,
    PG_CONNECTION_PARAM_NAME,
    SES_EMAIL_ADDRESS,
} = process.env;
console.log(`PG_CONNECTION_PARAM_NAME=${PG_CONNECTION_PARAM_NAME}`)

/** Test entrypoint for local debugging. */
handler(null, null);