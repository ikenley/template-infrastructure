const { AWS_REGION, USERS_TABLE_NAME, PREDICTIONS_TABLE_NAME } = process.env;

const AWS = require("aws-sdk");
AWS.config.update({
  region: AWS_REGION,
});
const dbClient = new AWS.DynamoDB({ region: AWS_REGION });

exports.handler = async function (event, context) {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  const todayDateIso = getTodayDateIso();
  console.log("today: \n" + JSON.stringify(todayDateIso, null, 2));

  const predictionItems = await getPredictionsByDate(todayDateIso);
  console.log("predictionItems: \n" + JSON.stringify(predictionItems, null, 2));

  const predictions = mapPredictionItems(predictionItems);
  console.log("predictions: \n" + JSON.stringify(predictions, null, 2));

  // TODO consider moving this to SQS
  // Probably fine at the current volume

  const userMap = await getUserMap(predictions);
  console.log("userMap: \n" + JSON.stringify(userMap, null, 2));

  return context.logStreamName;
};

const getTodayDateIso = () => {
  const d = new Date();
  const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  return today.toISOString();
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
