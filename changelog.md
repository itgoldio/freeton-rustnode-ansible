## 1.1.0

Monitoring Added 
- [telegraf](https://www.influxdata.com/time-series-platform/telegraf/) collect and send statistics
- [Grafana](https://grafana.com/) show statistics dashbord
- [InfluxDB](https://www.influxdata.com/) db for metrics
- [Chronograf](https://www.influxdata.com/time-series-platform/chronograf/) GUI for InfluxDb

Several scripts added for monitoring node and network state
- ton-env (list of variables)
- ton-check-env ( service script. It's checking variables)
- ton-depool-balance (check depool balance)
- ton-depool-proxy-1-balance (check depool proxy 1 balance)
- ton-depool-proxy-2-balance (check depool proxy 2 balance)
- ton-wallet-balance (check wallet balance)
- ton-election-date-end (show date end of current election cycle)
- ton-election-date-start (show date start of current election cycle)
- ton-election-state (show election state)
- ton-node-diff (show time diff for local node)
- ton-wallet-transaction-count (show count of unsigned transactions between wallet and depool)
- ton-depool-ticktok (send ticktok command to depool)
- ton-wallet-transaction-confirm (confirm unsigned transactions between wallet and depool)

Files path was changed 
- /opt/freeton -> /opt/freeton/bin (ton_node executable file)
- /var/lib/freeton -> /opt/freeton/db (db for node)
- /etc/freeton/contracts -> /opt/freeton/contracts (popular smart contracts)
- /var/log/freeton -> /opt/freeton/logs (node logs)

New path added
- /opt/freeton/scripts (scrip[ts for node])
- /opt/freeton/election (information about electoral cycles)
- /home/freeton/ton-keys (keys and addresses for walletr and depool)

Access mode for files is changed
- add executabel rule for group 'freeton'
- remove access for group 'other' 

Some variables added
- Need to recompile source code force 

Some command line parametrs added
- "flush" tag for change network

## 1.0.0

Install freeton rust node use ansible playbook