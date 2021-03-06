local nomad = import '../nomad.libsonnet';
local time = import '../time.libsonnet';

nomad.Job('countdash', {
  groups: [
    nomad.Group('api', {
      networks: [
        nomad.BridgeNetwork,
      ],
      services: [
        nomad.Service('count-api', {
          port: '9001',
          Connect: {
            SidecarService: {},
          },
          Checks: [
            nomad.HTTPCheck {
              path: '/health',
              Name: 'api-health',
              Expose: true,
              Interval: 10 * time.second,
              Timeout: 3 * time.second,
            },
          ],
        }),
      ],
      tasks: [
        nomad.DockerTask('web', {
          image: 'hashicorpnomad/counter-api:v3',
        }),
      ],
    }),
    nomad.Group('dashboard', {
      networks: [
        nomad.BridgeNetwork {
          ports: [
            { name: 'http', to: 9002 },
          ],
        },
      ],
      services: [
        nomad.Service('count-dashboard', {
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
        }),
      ],
      tasks: [
        nomad.DockerTask('dashboard', {
          image: 'hashicorpnomad/counter-dashboard:v3',
          Env: {
            COUNTING_SERVICE_URL: 'http://${NOMAD_UPSTREAM_ADDR_count_api}',
          },
        }),
      ],
    }),
  ],
})
