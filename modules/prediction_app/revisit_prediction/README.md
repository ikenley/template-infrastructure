#

"CRON job"-like Lambda function which runs once a day and sends out reminder emails for Predictions.

See [prediction-app](https://github.com/ikenley/prediction-app).

Note: Only `./src` is bundled in the lambda function. Everything else is for local debugging.

---

## Local Debugging

```
cd modules\prediction_app\revisit_prediction_function\src
npm i
npm run start
```