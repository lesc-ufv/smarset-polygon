import time, threading
import pandas as pd
from API import Api

def extractContracts(threadNumber, api, addresses, results):
    countVerifiedContracts = 0
    countUnverifiedContracts = 0

    for i in range(len(addresses)):
        print("Thread {}: Extraindo o contrato {}...".format(threadNumber, i+1))

        address = addresses[i]
        result = api.getContractSourceCode(address)
        
        if result:
            countVerifiedContracts += 1
        else:
            countUnverifiedContracts += 1
    
    results.append((countVerifiedContracts, countUnverifiedContracts))

start = time.time()

api = Api()
df = pd.read_csv("addresses_polygon.csv")
addresses = df["address"].to_list()
listOfResults = []
listOfThreads = []
countVerifiedContracts = 0
countUnverifiedContracts = 0

numberOfAddressPerThread = int(len(addresses)/3)
addressesForThred0 = addresses[0:numberOfAddressPerThread]
addressesForThred1 = addresses[numberOfAddressPerThread:numberOfAddressPerThread*2]
addressesForThred2 = addresses[numberOfAddressPerThread*2:]

for i in range(3):
    if i == 0:
        args = (i, api, addressesForThred0, listOfResults)
    elif i == 1:
        args = (i, api, addressesForThred1, listOfResults)
    else:
        args = (i, api, addressesForThred2, listOfResults)

    thread = threading.Thread(target=extractContracts, args=args)
    listOfThreads.append(thread)
    thread.start()

for thread in listOfThreads:
    thread.join()

for result in listOfResults:
    countVerifiedContracts += result[0]
    countUnverifiedContracts += result[1]

end = time.time()

print("Algoritmo executado em {} minutos!".format((end - start)/60))
print("{} contratos(s) verificados!".format(countVerifiedContracts))
print("{} contratos(s) nao verificados!".format(countUnverifiedContracts))
