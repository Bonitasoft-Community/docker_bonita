BEGIN {
	print "handlers = java.util.logging.ConsoleHandler\n"
	print ".handlers = java.util.logging.ConsoleHandler"
	print "# The default logging level when not specifically defined"
	print ".level= INFO\n"
	print "# The minimum level to log"
	print "java.util.logging.ConsoleHandler.level = INFO"
	print "java.util.logging.ConsoleHandler.formatter = org.apache.juli.BonitaSimpleFormatter\n"
}
($0 ~ /^##### DO NOT MODIFY THIS LINE.*/) { started = ! started; next }
started { print }