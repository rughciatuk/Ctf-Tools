#!/bin/bash -eu

proxy=localhost:8888

while getopts ":p:" opt; do
	case $opt in
    	p)
	      	proxy="$OPTARG"
	      	;;
    	\?)
	      	echo "Invalid option: -$OPTARG" >&2
	      	;;
	esac
done

shift $((OPTIND-1))

echo "Connecting to Charles: $proxy"
cert_file=$(mktemp -t charles-ca-cert.XXXXXX)
curl -s http://ssl.charles/ --proxy "$proxy" > "$cert_file"


if [ -z "${JAVA_HOME:-}" ]; then
	echo "JAVA_HOME environment variable not found. Not patching any JDK."
else
	if [ ! -f "$JAVA_HOME"/jre/lib/security/cacerts ]; then
		echo "Could not find cacerts file: $JAVA_HOME/jre/lib/security/cacerts"
	else 
		echo "Found JDK: $JAVA_HOME"

		echo
		echo "Adding Charles SSL CA certificate to JDK cacerts file:"
		echo "$JAVA_HOME"/jre/lib/security/cacerts
		echo "This may require your password for sudo."

		sudo keytool -import -noprompt -alias charles-$(date +%Y%m%d%H%M%S) -file "$cert_file" -keystore "$JAVA_HOME"/jre/lib/security/cacerts -storepass changeit
		echo
	fi
fi

rm -f "$cert_file"
