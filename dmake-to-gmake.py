#!/usr/bin/python

import os
import sys
import re

MAKELINE = "^(?:\$\(([^:=\$)]+)\)\s?)?([^#\s=:/]+)\s*([:\+]?=?)(?:\s*(.*))$"
SHELL_VARIABLE = "\$\((([^:]+):sh)\)"

SPECIAL_VARS = [
	"BOOT_SUBDIRS",
	"COMMON_CRT",
	"ETCSECURITYDFILES",
	"IPCTF_TARGET",
	"KMODS",
	"LINT_MODULE",
	"MACH",
	"MACH64",
	"MODULE",
	"MSGLIBNAME",
	"OBJECTS",
	"PMTMO_FILE",
	"ROOTDIR",
	"ROOTLIBDIR",
	"ROOTSVCMETHODDIR",
	"ROOT_MOD_DIR",
	"SUBDIRS",
]

class dmakeTogmake(object):

	def __init__(self, args):
		self.continuation = False
		self.conditional = None
		if args:
			for path in args:
				if os.path.isdir(path):
					self.process_subdir(path)
				else:
					self.process_makefile(path)
		else:
			self.process_subdir(os.getcwd())

	def process_line(self, outfp, line):
		offset = 0
		if self.continuation == False:
			match = re.match(MAKELINE, line)
			if match and match.group(2):
				conditional, variable, operand, value = match.groups()
                                #print match.groups()
				if conditional in SPECIAL_VARS:
					conditional = None
				if conditional:
					offset = len(conditional) + len("$()")
					line = line.replace(value, "%s" % value)
				match = re.search(SHELL_VARIABLE, value)
				if match:
					line = line.replace(match.group(1),
					    "shell $(%s)" % match.group(2))
				if conditional != self.conditional:
					if self.conditional:
						outfp.write("endif\n")
					if conditional:
						outfp.write("ifneq ($(%s),$(POUND_SIGN))\n" % conditional)
					self.conditional = conditional
			elif self.conditional:
				outfp.write("endif\n")
				self.conditional = False
		if ":" in line:
			line = line.replace(":=", ":")
			line = line.replace("$$(", "$(")
		line = line.replace(".WAIT", "")
		outfp.write(line[offset:]+"\n")

        def process_include(self, outfp, line):
                if "Makefile" in line:
                        newline = line.replace("Makefile", "GNUmakefile")
                else:        
                        newline = line + ".gnu"
		outfp.write(newline+"\n")

	def process_makefile(self, path):
                if "Makefile" in path:
			newpath = path.replace("Makefile", "GNUmakefile")
                else:
			newpath = path + ".gnu"
                print "Processing %s" % path    
		outfp = open(newpath, "w")
		for line in file(path, "r"):
			line = line.rstrip()
			if line.startswith("include"):
                                self.process_include(outfp, line)
			else:
				self.process_line(outfp, line)
			self.continuation = line.endswith("\\")
		outfp.close()

	def process_subdir(self, subdir):
		for entry in os.listdir(subdir):
			path = os.path.join(subdir, entry)
                        if os.path.islink(path):
                                pass
                        elif os.path.isdir(path):
				self.process_subdir(path)
			elif entry.startswith("Makefile"):
				self.process_makefile(path)
			elif entry in ("Targetdirs", "pmcs8001fw.version"):
				self.process_makefile(path)

if __name__ == "__main__":
	try:
		dtog = dmakeTogmake(sys.argv[1:])
	except KeyboardInterrupt:
		pass
