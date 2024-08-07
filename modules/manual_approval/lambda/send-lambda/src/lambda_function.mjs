console.log(`Loading function`);
import { SNS } from "@aws-sdk/client-sns";

export const handler = (event, context, callback) => {
  console.log(`event= ${JSON.stringify(event)}`);
  console.log(`context= ${JSON.stringify(context)}`);

  const executionContext = event.ExecutionContext;
  console.log(`executionContext= ${executionContext}`);

  const executionName = executionContext.Execution.Name;
  console.log(`executionName= ${executionName}`);

  const statemachineName = executionContext.StateMachine.Name;
  console.log(`statemachineName= ${statemachineName}`);

  const taskToken = executionContext.Task.Token;
  console.log(`taskToken= ${taskToken}`);

  const apigwEndpint = event.APIGatewayEndpoint;
  console.log(`apigwEndpint = ${apigwEndpint}`);

  const approveEndpoint = `${apigwEndpint}/execution?action=approve&ex=${executionName}&sm=${statemachineName}&taskToken=${encodeURIComponent(
    taskToken
  )}`;
  console.log(`approveEndpoint=${approveEndpoint}`);

  const rejectEndpoint = `${apigwEndpint}/execution?action=reject&ex=${executionName}&sm=${statemachineName}&taskToken=${encodeURIComponent(
    taskToken
  )}`;
  console.log(`rejectEndpoint= ${rejectEndpoint}`);

  const emailSnsTopic = event.EmailSnsTopic;
  console.log(`emailSnsTopic= ${emailSnsTopic}`);

  const baseMessage =
    event.Message ||
    `Welcome! This is an email requiring an approval for a step functions execution.`;

  const emailMessage = `${baseMessage}
  
Please check the following information and click "Approve" link if you want to approve.

Execution Name -> ${executionName}

Approve ${approveEndpoint}

Reject ${rejectEndpoint}`;

  const sns = new SNS();
  var params = {
    Message: emailMessage,
    Subject: "Required approval from AWS Step Functions",
    TopicArn: emailSnsTopic,
  };

  sns
    .publish(params)
    .then(function (data) {
      console.log(`MessageID is ${data.MessageId}`);
      callback(null);
    })
    .catch(function (err) {
      console.error(err, err.stack);
      callback(err);
    });
};

export default handler;
