import os
import sys

class Flag:
    def __init__(self, cmd, arg):
        sep = arg.find(':')
        self._cmd = cmd
        if sep == -1:
            self._name = arg[1:]
            self._value = ""
        else:
            self._name = arg[1:sep]
            self._value = arg[sep+1:]

    def cmd(self):
        return self._cmd

    def name(self):
        return self._name

    def value(self):
        return self._value

class Command:
    def __init__(self, cmd, args):
        self._cmd = cmd
        self._flags = {}

        for i in range(0, len(args)):
            if args[i][0] != '-':
                self._remaining_args = args[i:]
                return

            flag = Flag(cmd, args[i])
            self._flags[flag.name()] = flag

        self._remaining_args = []

    def cmd(self):
        return self._cmd

    def flags(self):
        return self._flags

    def remaining_args(self):
        return self._remaining_args

def run_build(command):
    output_file = ""

    object_extension = ".o"
    library_extension = ".so"
    binary_extension = ""
    if sys.platform == "windows":
        object_extension = ".obj"
        library_extension = ".dll"
        binary_extension = ".exe"
    elif sys.platform == "darwin":
        library_extension = ".dylib"

    args = []
    if "library" in command.flags():
        output_file = "build/libkrfw" + library_extension
        args += [ "./src/krfw/vulkan", "-build-mode:dynamic", "-out:" + output_file ]
    elif "objects" in command.flags():
        output_file = "build/krfw" + object_extension
        args += [ "./src/", "-build-mode:object", "-out:build/krfw" + object_extension ]
    else:
        output_file = "build/demo" + binary_extension
        args += [ "./src/", "-out:build/demo" + binary_extension ]

    if "debug" in command.flags():
        args += [ "-debug" ]
    elif "release" not in command.flags():
        args += [ "-debug" ]

    if "sanitize" in command.flags():
        match command.flags()["sanitize"].value():
            case "address":
                args += [ "-sanitize:address" ]
            case "memory":
                args += [ "-sanitize:memory" ]
            case "thread":
                args += [ "-sanitize:thread" ]

    return args, output_file

def main():
    args = sys.argv
    command = Command(args[1], args[2:])

    lldb = False
    argv = []
    output_file = ""
    match command.cmd():
        case "run":
            if "lldb" in command.flags():
                a, output_file = run_build(command)
                argv += [ "build" ] + a
                lldb = True
            else:
                a, output_file = run_build(command)
                argv += [ "run" ] + a
        case "build":
            a, output_file = run_build(command)
            argv += [ "build" ] + a

    pid = os.fork()
    if pid == 0:
        os.execvp("odin", [ "odin" ] + argv)
    
    _, status = os.wait()
    if status != 0:
        print("Odin build failed")
        sys.exit(1)

    if lldb:
        os.execvp("lldb", [ "lldb", output_file ])

if __name__ == "__main__":
    main()
