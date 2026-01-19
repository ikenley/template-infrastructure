import { SFN as StepFunctions } from "@aws-sdk/client-sfn";

const buildStepFunctionsRedirect = (lambdaArn, statemachineName, executionName) => {
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

  return {
    statusCode: 302,
    headers: {
      Location: url,
    },
  };
};

export const handler = async (event, context) => {
  console.log("Event= " + JSON.stringify(event));
  const action = event.queryStringParameters.action;
  const taskToken = event.queryStringParameters.taskToken;
  const statemachineName = event.queryStringParameters.sm;
  const executionName = event.queryStringParameters.ex;

  const stepfunctions = new StepFunctions();

  let message = "";

  if (action === "approve") {
    message = { action, message: "Approved! Task approved by ${var.email}" };
  } else if (action === "reject") {
    message = { action, message: "Rejected! Task rejected by ${var.email}" };
  } else {
    console.error("Unrecognized action. Expected: approve, reject.");
    throw new Error("Failed to process the request. Unrecognized Action.");
  }

  try {
    await stepfunctions.sendTaskSuccess({
      output: JSON.stringify(message),
      taskToken,
    });

    return buildStepFunctionsRedirect(
      context.invokedFunctionArn,
      statemachineName,
      executionName
    );
  } catch (err) {
    console.error(err, err.stack);
    throw err;
  }
};

export default handler;
