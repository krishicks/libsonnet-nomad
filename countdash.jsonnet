local nomad = import 'nomad.libsonnet';
local time = import 'time.libsonnet';

nomad.Job {
  name: 'countdash',
  groups: [
    nomad.Group {
      name: 'api',
      Networks: [
        nomad.NetworkBridge,
      ],
      services: [
        nomad.Service {
          name: 'count-api',
          port: '9001',
          Connect: {
            SidecarService: {},
          },
          Checks: [
            {
              Expose: true,
              Type: 'http',
              Name: 'api-health',
              Path: '/health',
              Interval: 10 * time.second,
              Timeout: 3 * time.second,
            },
          ],
        },
      ],
      tasks: [
        nomad.Task {
          name: 'web',
          driver: 'docker',
          config: {
            image: 'hashicorpnomad/counter-api:v3',
          },
        },
      ],
    },
    nomad.Group {
      name: 'dashboard',
      Networks: [
        nomad.NetworkBridge {
          ReservedPorts: [
            {
              Label: 'http',
              To: 9002,
              Value: 9002,
            },
          ],
        },
      ],
      services: [
        nomad.Service {
          name: 'count-dashboard',
          port: '9002',
          Connect: {
            SidecarService: {
              Proxy: {
                Upstreams: [
                  {
                    DestinationName: 'count-api',
                    LocalBindPort: 8080,
                  },
                ],
              },
            },
          },
        },
      ],
      tasks: [
        nomad.Task {
          name: 'dashboard',
          driver: 'docker',
          config: {
            image: 'hashicorpnomad/counter-dashboard:v3',
          },
          Env: {
            COUNTING_SERVICE_URL: 'http://${NOMAD_UPSTREAM_ADDR_count_api}',
          },
        },
      ],
    },
  ],
}