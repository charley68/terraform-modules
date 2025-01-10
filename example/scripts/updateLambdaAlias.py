import boto3
import os


def get_lambda_functions_with_preprod_and_tags():
    # Initialize AWS Lambda client
    client = boto3.client('lambda', region_name='eu-west-2')  # Set your region if different

    # List all Lambda functions
    functions = client.list_functions()['Functions']
    lambda_with_tags = []

    # Iterate through each function
    for function in functions:
        function_name = function['FunctionName']

        # Check for the tag "project" with value "MAXAI"
        tags = client.list_tags(Resource=function['FunctionArn']).get('Tags', {})
        if tags.get('project') == 'maxaiAPI':
            
            # Check if there is a "preProd" alias for this function
            aliases = client.list_aliases(FunctionName=function_name)['Aliases']
            for alias in aliases:
                if alias['Name'] == 'preProd':
                    lambda_with_tags.append(function['FunctionArn'])
                    break

    return lambda_with_tags


def update_or_create_alias_with_permissions(api_gateway_arn):
    lambda_client = boto3.client('lambda', region_name=os.getenv('AWS_REGION'))
    alias_name = "prod"

    # Derive the function name from the ARN (after the last '/')
    function_name = api_gateway_arn.split(':')[-1]

    try:
        # Publish the latest version of the Lambda function
        response = lambda_client.publish_version(FunctionName=function_name)
        latest_version = response['Version']

        # Check if the alias exists
        try:
            alias = lambda_client.get_alias(FunctionName=function_name, Name=alias_name)
            current_version = alias['FunctionVersion']

            # Update the alias only if the version is different
            if current_version != latest_version:
                print(f"Updating alias '{alias_name}' for lambda: {function_name} to version {latest_version}.")
                lambda_client.update_alias(
                    FunctionName=function_name,
                    Name=alias_name,
                    FunctionVersion=latest_version
                )
            else:
                print(f"Alias '{alias_name}' for lambda: {function_name}  already points to version {latest_version}, no update needed.")

        except lambda_client.exceptions.ResourceNotFoundException:
            print(f"Alias '{alias_name}' does not exist for function {function_name}.")
            exit(-1)

    except Exception as e:
        print(f"Failed to process function {function_name}: {e}")
        exit(-1)


if __name__ == "__main__":
    # Get the list of Lambda functions with the "preProd" alias and specific tags
    endpoints = get_lambda_functions_with_preprod_and_tags()

    if endpoints:
        for endpoint in endpoints:
            update_or_create_alias_with_permissions(endpoint)
