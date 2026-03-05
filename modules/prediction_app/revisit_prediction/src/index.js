const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const { DynamoDBClient, BatchGetItemCommand } = require("@aws-sdk/client-dynamodb");
const { Pool } = require("pg");

let pool = null;

exports.handler = async function (_event, _context) {
  const { AWS_REGION, PG_CONNECTION_PARAM_NAME, SES_EMAIL_ADDRESS, USER_TABLE_NAME } =
    process.env;
  console.log("revisit-prediction started", {
    AWS_REGION,
    PG_CONNECTION_PARAM_NAME,
    SES_EMAIL_ADDRESS,
    USER_TABLE_NAME
  });

  const todayDateIso = getTodayDateIso();

  const predictions = await getPredictionsByDate(
    AWS_REGION,
    PG_CONNECTION_PARAM_NAME,
    todayDateIso
  );
  console.log("predictions: \n" + JSON.stringify(predictions, null, 2));

  const dynamoClient = new DynamoDBClient({ region: AWS_REGION });
  const predictionsWithEmail = await attachEmails(dynamoClient, USER_TABLE_NAME, predictions);

  // Long term, consider moving this to SQS
  // Probably fine at the current volume
  const sesClient = new SESClient({ region: AWS_REGION });
  for (let p of predictionsWithEmail) {
    await sendEmail(sesClient, SES_EMAIL_ADDRESS, p);
  }

  return _context.logStreamName;
};

const getTodayDateIso = () => {
  const d = new Date();
  const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const todayIsoString = today.toISOString();
  console.log("todayIsoString", todayIsoString);
  return todayIsoString;
};

const getPredictionsByDate = async (
  awsRegion,
  pgConnectionParamName,
  todayDateIso
) => {
  if (!pool) {
    pool = await getPool(awsRegion, pgConnectionParamName);
  }

  try {
    const query = `
select p.id
    , p.name
    , p.user_id
from prediction.prediction p
where date_trunc('day', p.revisit_on) = date_trunc('day', $1::timestamp)
;`
    console.log("query", query);
    const data = await pool.query(query
      ,
      [todayDateIso]
    );
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
};

/** Gets Postgres config information from SSM Parameter store */
const getPgConfig = async (awsRegion, pgConnectionParamName) => {
  const client = new SSMClient({ region: awsRegion });
  const command = new GetParameterCommand({
    Name: pgConnectionParamName,
    WithDecryption: true,
  });

  const response = await client.send(command);
  const pgConfig = JSON.parse(response.Parameter.Value);
  return pgConfig;
};

const attachEmails = async (dynamoClient, userTableName, predictions) => {
  if (!predictions || predictions.length === 0) {
    return predictions
  };

  const userIds = [...new Set(predictions.map(p => p.user_id))];

  const keys = userIds.map(id => ({ id: { S: id } }));
  const command = new BatchGetItemCommand({
    RequestItems: {
      [userTableName]: { Keys: keys, ProjectionExpression: "id, email" }
    }
  });

  const response = await dynamoClient.send(command);
  const items = response.Responses[userTableName] ?? [];
  const emailMap = Object.fromEntries(items.map(item => [item.id.S, item.email.S]));
  console.log("emailMap", emailMap);

  return predictions.map(p => ({ ...p, email: emailMap[p.user_id] }));
};

const sendEmail = async (sesClient, sourceEmailAddress, prediction) => {
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
    Source: sourceEmailAddress,
    ReplyToAddresses: [sourceEmailAddress],
  };

  try {
    const command = new SendEmailCommand(params);
    const response = await sesClient.send(command);
    console.log("MessageId", response.MessageId);
  } catch (err) {
    console.error(err);
  }
};
