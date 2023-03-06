const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const { Pool } = require("pg")

let pool = null;

exports.handler = async function (_event, _context) {
  const {
    AWS_REGION,
    PG_CONNECTION_PARAM_NAME,
    SES_EMAIL_ADDRESS,
  } = process.env;

  const todayDateIso = getTodayDateIso();

  const predictions = await getPredictionsByDate(AWS_REGION, PG_CONNECTION_PARAM_NAME, todayDateIso);
  console.log("predictions: \n" + JSON.stringify(predictions, null, 2));

  // Long term, consider moving this to SQS
  // Probably fine at the current volume
  for (let p of predictions) {
    await sendEmail(p);
  }

  return context.logStreamName;
};

const getTodayDateIso = () => {
  const d = new Date();
  const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const todayIsoString = today.toISOString();
  console.log("todayIsoString", todayIsoString);
  return todayIsoString;
};

const getPredictionsByDate = async (awsRegion, pgConnectionParamName, todayDateIso) => {
  if (!pool) {
    pool = await getPool(awsRegion, pgConnectionParamName)
  }

  try {
    const data = await pool.query(`
select p.id
    , p.name
    , u.email
from prediction.prediction p
join iam.user u
  on p.user_id = u.id
where date_trunc('day', p.revisit_on) = date_trunc('day', $1::timestamp)
;`, [todayDateIso]);
    return data.rows;
  } catch (err) {
    console.error(err);
  }
};

/** Gets Postgres connection pool */
const getPool = async (awsRegion, pgConnectionParamName) => {
  const config = await getPgConfig(awsRegion, pgConnectionParamName);
  const pool = new Pool(config);
  return pool;
}

/** Gets Postgres config information from SSM Parameter store */
const getPgConfig = async (awsRegion, pgConnectionParamName) => {
  const client = new SSMClient({ region: awsRegion });
  const command = new GetParameterCommand({
    Name: pgConnectionParamName,
    WithDecryption: true
  });

  const response = await client.send(command);
  const pgConfig = JSON.parse(response.Parameter.Value);
  return pgConfig;
}

const sendEmail = async (prediction) => {
  const params = {
    Destination: {
      ToAddresses: [prediction.email],
    },
    Message: {
      Body: {
        Html: {
          Charset: "UTF-8",
          Data: `<html><body>It's time to check back in on your prediction about <a href="https://predictions.ikenley.com/p/${prediction.id}">${prediction.name}</a></body></html>`,
        },
        Text: {
          Charset: "UTF-8",
          Data: `It's time to check back in on your prediction about ${prediction.name}: https://predictions.ikenley.com/p/${prediction.id}`,
        },
      },
      Subject: {
        Charset: "UTF-8",
        Data: `Remember when you cared about ${prediction.name}?`,
      },
    },
    Source: SES_EMAIL_ADDRESS,
    ReplyToAddresses: [SES_EMAIL_ADDRESS],
  };

  try {
    const response = await sesClient.sendEmail(params).promise();
    console.log("MessageId", response.MessageId);
  } catch (err) {
    console.error(err);
  }
};
