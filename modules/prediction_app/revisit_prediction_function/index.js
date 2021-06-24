// Load the AWS SDK for Node.js
// var AWS = require('aws-sdk');
// // Set the region
// AWS.config.update({region: 'REGION'});

// // Create DynamoDB service object
// var ddb = new AWS.DynamoDB({apiVersion: '2012-08-10'});

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

  const today = getTodayDate();
  console.log("today: \n" + JSON.stringify(today, null, 2));

  return context.logStreamName;
};

const getTodayDate = () => {
  const d = new Date();
  const today = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  return today;
};
