# speedtest-cli-extras

This repository contains tools that enhance the [speedtest-cli] command-line interface to [speedtest.net].
This fork of [speedtest-cli-extras] extends the script by adding options to send results to an 
[IFTTT Maker Channel] or [Loggly].

## Prerequisites
This script requires Python and [speedtest-cli]. If you have a working Python installation, chances are you have a package manager such as [pip]. Installing speedtest-cli is then as easy as running
```
$ pip install speedtest-cli
```

## Usage

```
./speedtest-extras.sh [-d] [-c] [-h] [-i secret-key] [-l]
    -d: debugging-mode (reuses previously logged speedtest result instead of queriying speedtest - faster)
    -c: CSV mode
    -h: Print CSV header (only if used together with the -c flag)
    -i: IFTTT mode. Takes the IFTTT Maker Channel secret key as argument (required)
    -l: Loggly mode
```

### Example: CSV Mode

Generate headers (e.g. to start a new CSV file):
```
$ ./speedtest-extras.sh -c -h
start;stop;from;from_ip;server;server_dist;server_ping;download;upload;share_url
```

Run speedtest and output results in CSV format:
```
$ ./speedtest-extras.sh -c
2014-09-06 10:07:51;2014-09-06 10:09:31;Comcast Cable;73.162.87.38;AT&T (San Francisco, CA);20.22 km;24.536 ms;44.25 Mbits/s;4.93 Mbits/s;http://www.speedtest.net/result/3741180214.png
```

The above examples print the output to STDOUT (the terminal). To record results into a file instead, use something like:
```
$ ./speedtest-extras.sh -c -h >> file.csv
$ ./speedtest-extras.sh -c >> file.csv
```
Every subsquent run of speedtest-extras.sh will add another line to _file.csv_.

### Example: IFTTT Mode

You will need to setup a [IFTTT Maker Channel] first. Once this is done, IFTTT will display a unique key for you to send
events to that channel. You will need this key to run speedtest-extras.sh in IFTTT mode.

```
$ ./speedtest-extras.sh -i <YOUR-PRIVATE-KEY>
```
If the event was successfully triggered, the script will not generate any output. Check your IFTTT channel to make sure everything is working. Connect this channel to another action as you like, for example to add a line to a Google Spreadsheet.

### Example: Loggly Mode

You will need a Loggly account for this to work (the free account should be fine). Use your own customer token (found under Source Setup > Customer Tokens in your Loggly dashboard) to call the script:
```
$ ./speedtest-extras.sh -l <YOUR-CUSTOMER-TOKEN>
```
If the event was successfully triggered, the script will not generate any output. Check your Loggly events to make sure everything is working.

## Details

The `speedtest-extras` bash script calls `speedtest-cli`, captures its output, reformats it, and either outputs it on a single line with time stamps and values separated by _semicolons_<sup>*</sup>, sends it to an [IFTTT Maker Channel] called _speedtest_ or to [Loggly] tagged as _speedtest_.

_Footnotes:_  
(*) Commas are not safe to use to separate the values, because some test servers report speeds with commas instead of periods.  Because of this, semicolons are used instead.

## References

This is a fork of [speedtest-cli-extras] by Henrik Bengtsson. 
The export to IFTTT was inspired by [a project on Make: Magazine by Alasdair Allan](http://makezine.com/projects/send-ticket-isp-when-your-internet-drops/).
The export to Loggly was inspired by [this post from Stephen Phillips](http://blog.scphillips.com/posts/2015/05/monitoring-broadband-speed-with-loggly/).


[speedtest-cli]: https://github.com/sivel/speedtest-cli
[speedtest.net]: http://www.speedtest.net/
[speedtest-cli-extras]: https://github.com/HenrikBengtsson/speedtest-cli-extras
[IFTTT Maker Channel]: https://ifttt.com/maker
[Loggly]: https://www.loggly.com
[pip]: https://pip.pypa.io/en/stable/