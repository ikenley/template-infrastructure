const { AWS_REGION, USERS_TABLE_NAME, PREDICTIONS_TABLE_NAME } = process.env;

const AWS = require("aws-sdk");
AWS.config.update({
  region: AWS_REGION,
});
const dbClient = new AWS.DynamoDB({ region: AWS_REGION });

// var params = {
//   ExpressionAttributeValues: {
//     ':s': {N: '2'},
//     ':e' : {N: '09'},
//     ':topic' : {S: 'PHRASE'}
//   },
//   KeyConditionExpression: 'Season = :s and Episode > :e',
//   ProjectionExpression: 'Episode, Title, Subtitle',
//   FilterExpression: 'contains (Subtitle, :topic)',
//   TableName: 'EPISODES_TABLE'
// };

// ddb.query(params, function(err, data) {
//   if (err) {
//     console.log("Error", err);
//   } else {
//     //console.log("Success", data.Items);
//     data.Items.forEach(function(element, index, array) {
//       console.log(element.Title.S + " (" + element.Subtitle.S + ")");
//     });
//   }
// });

exports.handler = async function (event, context) {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  const todayDateIso = getTodayDateIso();
  console.log("today: \n" + JSON.stringify(todayDateIso, null, 2));

  return context.logStreamName;
};

const getTodayDateIso = () => {
  const d = new Date();
  const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  return today;
};

// const getPredictionsByDate = async (todayDateIso) => {
//   var params = {
//     TableName: PREDICTIONS_TABLE_NAME,
//     Key: {
//         RevisitOn: { S: todayDate },
//     },
//   };

//   try {
//     const data = await dbClient.getItem(params).promise();
//     return data.Item;
//   } catch (err) {
//     console.error(err);
//   }
// };
