import { SFN as StepFunctions } from "@aws-sdk/client-sfn";

var redirectToStepFunctions = function (
  lambdaArn,
  statemachineName,
  executionName,
  callback
) {
  const lambdaArnTokens = lambdaArn.split(":");
  const partition = lambdaArnTokens[1];
  const region = lambdaArnTokens[3];
  const accountId = lambdaArnTokens[4];

  console.log("partition=" + partition);
  console.log("region=" + region);
  console.log("accountId=" + accountId);

  const executionArn =
    "arn:" +
    partition +
    ":states:" +
    region +
    ":" +
    accountId +
    ":execution:" +
    statemachineName +
    ":" +
    executionName;
  console.log("executionArn=" + executionArn);

  const url =
    "https://console.aws.amazon.com/states/home?region=" +
    region +
    "#/executions/details/" +
    executionArn;
  callback(null, {
    statusCode: 302,
    headers: {
      Location: url,
    },
  });
};

export const handler = (event, context, callback) => {
  console.log("Event= " + JSON.stringify(event));
  const action = event.queryStringParameters.action;
  const taskToken = event.queryStringParameters.taskToken;
  const statemachineName = event.queryStringParameters.sm;
  const executionName = event.queryStringParameters.ex;

  const stepfunctions = new StepFunctions();

  var message = "";

  if (action === "approve") {
    message = { action, message: "Approved! Task approved by ${var.email}" };
  } else if (action === "reject") {
    message = { action, message: "Rejected! Task rejected by ${var.email}" };
  } else {
    console.error("Unrecognized action. Expected: approve, reject.");
    callback({ Status: "Failed to process the request. Unrecognized Action." });
  }

  stepfunctions
    .sendTaskSuccess({
      output: JSON.stringify(message),
      taskToken,
    })
    .then(function (data) {
      redirectToStepFunctions(
        context.invokedFunctionArn,
        statemachineName,
        executionName,
        callback
      );
    })
    .catch(function (err) {
      console.error(err, err.stack);
      callback(err);
    });
};

export default handler;
