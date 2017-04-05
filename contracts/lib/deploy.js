import Eth from 'ethjs';
import SignerProvider from 'ethjs-provider-signer';
import { sign } from 'ethjs-signer';
import { padToEven } from 'ethjs-util'; // eslint-disable-line
import fs from 'fs';

import contracts from './contracts.json';
import account from '../../../../../account.json';

const provider = new SignerProvider('https://ropsten.infura.io', {
  signTransaction: (rawTx, cb) => cb(null, sign(rawTx, account.privateKey)),
  accounts: cb => cb(null, [account.address]),
});
const eth = new Eth(provider);
const defaultTxObject = {
  gas: new Eth.BN(3000000),
  from: account.address,
};

function getTransactionSuccess(txHash, callback) {
  const cb = callback || function cb() {};
  const timeout = 170000;
  let count = 0;
  return new Promise((resolve, reject) => {
    const txInterval = setInterval(() => {
      eth.getTransactionReceipt(txHash, (err, result) => {
        if (err) {
          clearInterval(txInterval);
          cb(err, null);
          reject(err);
        }

        if (!err && result) {
          clearInterval(txInterval);
          cb(null, result);
          resolve(result);
        }
      });

      if (count >= timeout) {
        clearInterval(txInterval);
        const errMessage = `Receipt timeout waiting for tx hash: ${txHash}`;
        cb(errMessage, null);
        reject(errMessage);
      }
      count += 7000;
    }, 7000);
  });
}

function bnToString(objInput, baseInput, hexPrefixed) {
  var obj = objInput; // eslint-disable-line
  const base = baseInput || 10;

  // obj is an array
  if (typeof obj === 'object' && obj !== null) {
    if (Array.isArray(obj)) {
      // convert items in array
      obj = obj.map(item => bnToString(item, base, hexPrefixed));
    } else {
      if (obj.toString && (obj.lessThan || obj.dividedToIntegerBy || obj.isBN || obj.toTwos)) { // eslint-disable-line
        return hexPrefixed ? `0x${padToEven(obj.toString(16))}` : obj.toString(base);
      } else { // eslint-disable-line
        // recurively converty item
        Object.keys(obj).forEach((key) => {
          obj[key] = bnToString(obj[key], base, hexPrefixed);
        });
      }
    }
  }

  return obj;
}

const BoardRoom = eth.contract(
  JSON.parse(contracts.BoardRoom.interface),
  contracts.BoardRoom.bytecode,
  defaultTxObject
);

const OpenRules = eth.contract(
  JSON.parse(contracts.OpenRules.interface),
  contracts.OpenRules.bytecode,
  defaultTxObject
);


async function deployBoard() {
  try {
    const rulesTxHash = await OpenRules.new();
    const rulesReceipt = await getTransactionSuccess(rulesTxHash);
    const boardTxHash = await BoardRoom.new(rulesReceipt.contractAddress);
    const boardReceipt = await getTransactionSuccess(boardTxHash);
    const outputObject = bnToString({
      ropsten: {
        BoardRoom: Object.assign({}, boardReceipt, {
          interface: contracts.BoardRoom.interface,
          bytecode: contracts.BoardRoom.bytecode,
        }),
        OpenRules: Object.assign({}, rulesReceipt, {
          interface: contracts.OpenRules.interface,
          bytecode: contracts.OpenRules.bytecode,
        }),
      },
    });

    console.log('Contracts deployed: ', outputObject);

    return outputObject;
  } catch (err) {
    console.log('Error while deployment', err);
  }

  return {};
}

deployBoard()
.then((outputObject) => {
  fs.writeFile('./src/contracts/lib/environments.json', JSON.stringify(outputObject, null, 2), (err) => { // eslint-disable-line
    if (err) {
      return console.log('Error while writting file', err);
    }

    console.log('The file was saved!');
  });
})
.catch((deploymentError) => {
  console.log('Error while deploying', deploymentError);
});
