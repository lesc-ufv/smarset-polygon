import requests
from utils import API_KEY, BASE_URL

class Api:
    def __init__(self):
        self.baseUrl = BASE_URL
        self.apiKey = API_KEY
    
    def getContractSourceCode(self, contractAddress):
        try:
            params = {
                "module": "contract",
                "action" : "getsourcecode",
                "address" : contractAddress,
                "apikey" : self.apiKey
            }
            response = requests.get(self.baseUrl, params=params)
            data = response.json()
            if data["message"] == "OK":
                result = data["result"]
                sourceCode = result[0]["SourceCode"]
                if sourceCode != "":
                    outputFile = open("dataset/{}.sol".format(contractAddress), "w", encoding="utf-8")
                    outputFile.write(sourceCode)
                    outputFile.close()
                    return True
            return False
        except Exception as e:
            logFile = open("log.txt", "a", encoding="utf-8")
            logFile.write("{} => {}\n".format(contractAddress, e))
            logFile.close()
            return False
