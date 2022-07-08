This is a repository for some CodeDx scripts to automate the workflow for a CI/CD Pipeline.
The usage of the script is pretty straightforward. You use it like this:
./RunAnalysis.sh --user $USER --pass $PASS --cdx-url "http://yourcodedxurl.com:port" --project-id $ProjectID

If you are using the API key(Preferred) run it like this:
./RunAnalysis-api.sh --api-key $API_KEY --cdx-url "http://yourcodedxurl.com:port" --project-id $ProjectID
