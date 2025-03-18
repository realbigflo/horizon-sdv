/*
 #############################################################################
 # Copyright (c) 2024-2025 Accenture, All Rights Reserved.
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #         http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #
 # -----------------------------------------------------
 # http://www.accenture.com
 # -----------------------------------------------------
 # Description:
 #
 # Automates the setup and configuration of an MTK Connect agent and
 # testbench/device creation.
 #
 # 1. It loads environment variables from a .env file using dotenv.
 # 2. It sets up axios with a base URL and authentication credentials
 #    from the environment.
 # 3. It calls:
 #    - configureAgent which:
 #      - Checks if an agent with a specific registration already exists.
 #      - If not, creates a new agent and sets its permissions.
 #    - configureDevices:
 #      - Creates or updates devices associated with the agent.
 #      - Configures device interfaces (e.g., ADB, button, file system,
 #        MJPEG, terminal, touch, and tunnel).
 #      - Axios throws 403 when retrieving devices.
 #        - Retries up to 5 times on errors and random backoff time delay to
 #          workaround the issue.
 #
 #############################################################################
 */

'use strict';

require('dotenv').config();

const fs = require('fs');
const BPromise = require('bluebird');
const axios = require('axios');
const _ = require("lodash");

/**
 * Sets up the Axios configuration with a base URL and authentication
 * credentials from environment variables.
 */
const { MTK_CONNECT_DOMAIN, MTK_CONNECT_USERNAME, MTK_CONNECT_PASSWORD, MTK_CONNECT_REGISTRATION, MTK_CONNECT_TESTBENCH, MTK_CONNECT_DEVICES, MTK_CONNECT_HOST } = process.env;
const registration = MTK_CONNECT_REGISTRATION || fs.readFileSync('/usr/src/config/registration.name', 'utf-8');

axios.defaults.baseURL = `https://${MTK_CONNECT_DOMAIN}/mtk-connect`;
axios.defaults.auth = {
  username: MTK_CONNECT_USERNAME,
  password: MTK_CONNECT_PASSWORD
};

/**
 * Retries on 403 errors.
 */
let maxRetries = 5;

/**
 * The agent object that is created or retrieved by the code.
 */
let agent;

/**
 * Delays for random time between 0 and 2000 milliseconds.
 * Note: This is a crude workaround for AXIOS 403 Forbidden Errors
 */
async function delayMs(ms) {
  console.log(`delaying for ${ms}ms`);
  await new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Configures the agent by creating a new one or retrieving an existing one
 * with the registration name.
 */
async function configureAgent() {
  let agentResponse = await axios.get('/api/v1/agents', {params: {q: JSON.stringify({registration: registration})}})
  if (agentResponse.status === 200 && agentResponse.data.data.length === 1) {
    console.log(`agent with registration ${registration} already exists`);
    agent = agentResponse.data.data[0];
  } else {
    console.log(`creating agent using registration ${registration}`);
    agentResponse = await axios.post('/api/v1/agents', {
      name: MTK_CONNECT_TESTBENCH,
      registration: registration
    })
    agent = agentResponse.data.data;
    const data = {
      group: {
        name: 'everyone'
      },
      permission: 'book'
    }
    await axios.put(`/api/v1/agents/${agent.id}/permissions/group`, data)
  }
  console.log(`Created agent using registration ${registration}`);
}

/**
 * Configures the devices by creating them if they don't already exist.
 */
async function configureDevices() {
  await BPromise.mapSeries(_.times(MTK_CONNECT_DEVICES), configureDevice);
}

/**
 * Configures a single device by retrieving it or creating a new one.
 * @param {number} i - The index of the device to configure.
 */
async function configureDevice(i) {
  const index = i + 1;
  const q = {
    'agent.registration': registration,
    index: index
  }

  console.log(`device ${index} ... `);
  // Delay randomly to try to avoid AXIOS 403 Forbidden Errors
  await delayMs(Math.floor(Math.random() * 2000));

  const agentResponse = await axios.get('/api/v1/devices', {params: {q: JSON.stringify(q)}})
  if (agentResponse.status === 200 && agentResponse.data.data.length === 1) {
    console.log(`device ${index} already exists`);
  } else {
    console.log(`creating device ${index}`);
    await axios.post(`/api/v1/agents/${agent.id}/devices`, {
      name: `AAOS ${index}`
    });
  }
  const data = {
    interface: {
      'adb': {
        mode: 'tcp',
        port: 6520 + (index - 1),
        host: MTK_CONNECT_HOST
      },
      'button': {
        'driver': 'adb',
        'skin': 'Default Android'
      },
      'fs': {
        'types': [
          {
            'name': 'adb',
            'driver': 'adb',
            'root': '/'
          },
          {
            'name': 'HOST',
            'driver': 'native',
            'root': '/root'
          }
        ]
      },
      'log': {
        'types': [
          {
            'name': 'logcat',
            'driver': 'logcat'
          }
        ]
      },
      'mjpeg': {
        'types': [
          {
            'name': 'screen',
            'driver': 'minicap',
            'scale': 1.0
          }
        ]
      },
      'terminal': {
        'types': [
          {
            'name': 'adb',
            'driver': 'adb',
            'icon': 'adb'
          },
          {
            'name': 'HOST',
            'driver': 'spawn',
            'command': 'bash',
            'args': ['-c', 'cd ~/; bash --login', '']
          }
        ]
      },
      'touch': {
        'driver': 'adb',
        'native': true
      },
      'tunnel': {
        'types': [
          {
            'name': 'adb',
            'driver': 'adb'
          }
        ]
      }
    }
  }
  await axios.patch(`/api/v1/agents/${agent.id}/devices/${index}`, data);
  // Reset retry count
  maxRetries = 5;
}

async function main()  {
  try {
    console.log(`configureAgent`);
    await configureAgent();
  } catch (err) {
    throw err;
  }

  /**
   * Retry configureDevices up to 5 times on any error.
   * Note: This is a crude workaround for AXIOS 403 Forbidden Errors
   */
  console.log(`configureDevices`);
  while(maxRetries-- > 0) {
    try {
      await configureDevices();
      break;
    } catch (err) {
      if (maxRetries > 0) {
        console.log(`Error: retry configureDevices`);
        // Delay between 90s and 180s.
        await delayMs(Math.random() * (180000 - 90000) + 90000);
        continue;
      } else {
        throw err;
      }
    }
  }
}

main()
  .catch((err) => {
    console.error(err.message);
    process.exit(1);
  });
