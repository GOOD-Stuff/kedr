#!/bin/sh
#
# Usage:
#     test.sh function
# where
#	'function' - kernel function, call interception of which should be tested,

insmod_command=<$insmod_command$>
rmmod_command=<$rmmod_command$>

kedr_module_load_command="<$kedr_module_load_command$>"
kedr_module_name="<$kedr_module_name$>"

payload_module_name="trigger_payload_<$trigger_name$>"
payload_module="<$test_current_install_dir$>/trigger_payload/${payload_module_name}.ko"
target_module_name="trigger_target_<$trigger_name$>"
target_module="<$test_current_install_dir$>/trigger_target/${target_module_name}.ko"

if test $# -ne 1; then
	printf "Usage:\n\n\t%s function\n" "$0"
	exit 1
fi

function_name="$1"
shift

case "${function_name}" in
<$block: join(\n)$>
*)
	printf "Test is not intended for verify call interception of function %s.\n" "$function_name"
	exit 1
;;
esac

if ! ${kedr_module_load_command} "target_name=${target_module_name}"; then
	printf "Failed to load kedr core module\n"
	exit 1
fi

if ! $insmod_command ${payload_module} "function_name=${function_name}"; then
	printf "Failed to load payload module for testing call interception\n"
	$rmmod_command ${kedr_module_name}
	exit 1
fi

if ! $insmod_command ${target_module} "function_name=${function_name}"; then
	printf "Failed to load target module for testing call interception\n"
	$rmmod_command ${payload_module_name}
	$rmmod_command ${kedr_module_name}
	exit 1
fi


if test -n "$copy_to_user"; then
	dd bs=$user_buffer_size count=1 if=/dev/ttd of=/dev/null
elif test -n "$copy_from_user"; then
	dd bs=$user_buffer_size count=1 if=/dev/zero of=/dev/ttd
fi

is_intercepted=`cat /sys/module/${payload_module_name}/parameters/is_intercepted`

if ! $rmmod_command ${target_module_name}; then
	printf "Failed to unload target module.\n"
	exit 1
fi

if ! $rmmod_command ${payload_module_name}; then
	printf "Failed to unload payload module.\n"
	exit 1
fi

if ! $rmmod_command ${kedr_module_name}; then
	printf "Failed to unload kedr core module.\n"
	exit 1
fi


if ! test "$is_intercepted" -ne 0; then
	printf "Trigger program failed to trigger function call or KEDR failed to intercept this call.\n"
	exit 1
fi
