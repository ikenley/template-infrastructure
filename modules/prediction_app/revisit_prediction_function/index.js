const {
  AWS_REGION,
  USERS_TABLE_NAME,
  PREDICTIONS_TABLE_NAME,
  SES_EMAIL_ADDRESS,
} = process.env;

const AWS = require("aws-sdk");
AWS.config.update({
  region: AWS_REGION,
});
const dbClient = new AWS.DynamoDB({ region: AWS_REGION });
const sesClient = new AWS.SES({ region: AWS_REGION, apiVersion: "2010-12-01" });

exports.handler = async function (event, context) {
  const todayDateIso = getTodayDateIso();

  const predictionItems = await getPredictionsByDate(todayDateIso);

  const predictions = mapPredictionItems(predictionItems);
  console.log("predictions: \n" + JSON.stringify(predictions, null, 2));

  // TODO consider moving this to SQS
  // Probably fine at the current volume

  const userMap = await getUserMap(predictions);
  console.log("userMap: \n" + JSON.stringify(userMap, null, 2));

  for (let p of predictions) {
    const user = userMap[p.UserId];
    await sendEmail(p, user);
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

const getPredictionsByDate = async (todayDateIso) => {
  var params = {
    ExpressionAttributeValues: {
      ":r": { S: todayDateIso },
    },
    ExpressionAttributeNames: {
      "#n": "Name",
    },
    KeyConditionExpression: "RevisitOn = :r",
    ProjectionExpression: "Id, UserId, #n",
    //FilterExpression: "contains (Subtitle, :topic)",
    TableName: PREDICTIONS_TABLE_NAME,
    IndexName: "RevisitOn",
  };

  try {
    const data = await dbClient.query(params).promise();
    return data.Items;
  } catch (err) {
    console.error(err);
  }
};

const mapPredictionItems = (predictionItems) => {
  let predictions = predictionItems.map((p) => {
    return {
      Id: p.Id.S,
      UserId: p.UserId.S,
      Name: p.Name.S,
    };
  });

  return predictions;
};

const getUserMap = async (predictions) => {
  const userMap = {};

  for (const p of predictions) {
    const userId = p.UserId;
    if (!userMap[userId]) {
      const userItem = await getUser(userId);

      const user = {
        Id: userItem.Id.S,
        Email: userItem.Email.S,
      };

      userMap[userId] = user;
    }
  }

  return userMap;
};

const getUser = async (userId) => {
  var params = {
    TableName: USERS_TABLE_NAME,
    Key: {
      Id: { S: userId },
    },
  };

  try {
    const data = await dbClient.getItem(params).promise();
    return data.Item;
  } catch (err) {
    console.error(err);
  }
};

const sendEmail = async (prediction, user) => {
  const params = {
    Destination: {
      ToAddresses: [user.Email],
    },
    Message: {
      Body: {
        Html: {
          Charset: "UTF-8",
          Data: `<html><body>It's time to check back in on your prediction about <a href="https://predictions.ikenley.com/p/${prediction.Id}">${prediction.Name}</a></body></html>`,
        },
        Text: {
          Charset: "UTF-8",
          Data: `It's time to check back in on your prediction about ${prediction.Name}: https://predictions.ikenley.com/p/${prediction.Id}`,
        },
      },
      Subject: {
        Charset: "UTF-8",
        Data: `Remember when you cared about ${prediction.Name}?`,
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
