import dotenv from "dotenv";
dotenv.config();
import { handler } from "./src/index.js";

const context = {};

/** Test entrypoint for local debugging. */
handler(null, context);
