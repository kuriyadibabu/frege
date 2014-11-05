# Makefile for the frege compiler distribution

#
# Make sure you have sensible values for JAVAC, YACC and JAVA
# The standard distribution needs a Java 1.7 JDK.
# Because people may need previous JDKs/JREs for different work,
# there are 2 mechanisms to get the right java:
#
#   - put the JDK7 in your PATH after other JDKs, and make java7 a symbolic link to
#     the JDK7 java binary. (On Windows, just copy java.exe to java7.exe)
#   - For UNIX users: make the following alias:
#         alias fmake='make JAVA="/path/to/jdk7/java" -f frege.mk '
#
# YACC should be a BSD compatible yacc. This can be obtained from the net at various places.
# Windows users look for pbyacc.exe, Ubuntu users use
#
#	sudo apt-get install byacc-j  # byacc and pbyacc should also work
#

.SUFFIXES: .class .fr

JAVAC = javac -source 1.7 -target 1.7 -encoding UTF-8
YACC = /Developer/usr/bin/yacc
# JAVA = java7 -XX:+TieredCompilation "-Dfrege.javac=javac -J-Xmx512m"
# JAVA = java7 -XX:+TieredCompilation -Dfrege.javac=internal
JAVA = java "-Dfrege.javac=internal -nowarn -source 1.7 -target 1.7"


DOC  = ../frege.github.com/doc
DOCF = doc/frege/compiler
DIR1 = build/afrege
PREL1  = $(DIR1)/prelude
COMPF1  = $(DIR1)/compiler
LIBF1   = $(DIR1)/lib
DATA1   = $(DIR1)/data
CONTROL1 = $(DIR1)/control
LIBJ1   = $(DIR1)/j
TOOLSF1 = $(DIR1)/tools
DIR2 = build/bfrege
PREL2   = $(DIR2)/prelude
COMPF2  = $(DIR2)/compiler
LIBF2   = $(DIR2)/lib
DATA2   = $(DIR2)/data
LIBJ2   = $(DIR2)/j
TOOLSF2 = $(DIR2)/tools
DIR  = build/frege
PREL    = $(DIR)/prelude
COMPF   = $(DIR)/compiler
LIBF    = $(DIR)/lib
DATA   = $(DIR)/data
LIBJ    = $(DIR)/j
TOOLSF  = $(DIR)/tools
COMPS   = frege/compiler


FREGE    = $(JAVA) -Xss8m -Xmx1g -cp build

#	compile using the fregec.jar in the working directory
FREGECJ  = $(FREGE)  -jar fregec.jar  -d build -fp build -nocp -hints

#	compile compiler1 with fregec.jar, uses prelude sources from shadow/
FREGEC0  = $(FREGECJ) -prefix a -sp shadow:.

#	compile compiler2 with compiler1
FREGEC1  = $(FREGE) afrege.compiler.Main -d build -hints -inline -prefix b

#	compile final compiler with compiler2
FREGEC2  = $(FREGE) bfrege.compiler.Main -d build -hints -O

#	final compiler
FREGECC  = $(FREGE) frege.compiler.Main  -d build -hints -O

#	shadow Prelude files in the order they must be compiled
SPRELUDE  =  shadow/frege/prelude/PreludeBase.fr \
		shadow/frege/control/Semigroupoid.fr shadow/frege/control/Category.fr \
		shadow/frege/prelude/PreludeList.fr shadow/frege/prelude/PreludeMonad.fr \
		shadow/frege/prelude/Maybe.fr \
		shadow/frege/prelude/PreludeIO.fr \
		shadow/frege/java/Lang.fr \
		shadow/frege/prelude/PreludeArrays.fr \
		shadow/frege/java/util/Regex.fr \
		shadow/frege/prelude/PreludeText.fr \
		shadow/frege/prelude/Math.fr shadow/frege/prelude/Floating.fr
#	Prelude files in the order they must be compiled
PRELUDE  =  frege/prelude/PreludeBase.fr \
		frege/control/Semigroupoid.fr frege/control/Category.fr \
		frege/prelude/PreludeList.fr frege/prelude/PreludeMonad.fr \
		frege/prelude/Maybe.fr \
		frege/prelude/PreludeIO.fr \
		frege/java/Lang.fr \
		frege/prelude/PreludeArrays.fr \
		frege/java/util/Regex.fr \
		frege/prelude/PreludeText.fr \
		frege/prelude/Math.fr frege/prelude/Floating.fr

all:  frege.mk runtime compiler fregec.jar

shadow-prelude:
	jar -cf shadow.jar $(PRELUDE)
	cd shadow && jar -xf ../shadow.jar
	rm shadow.jar

clean:
	rm -rf build/afrege build/bfrege build/frege
	rm -rf build
	mkdir build

{frege/prelude}.fr{$(PREL1)}.class::
	$(FREGEC0) $<
# {frege/compiler}.fr{$(COMPF1)}.class::
#	$(FREGEC0) $<
# {frege/lib}.fr{$(LIBF1)}.class::
#	$(FREGEC0) $<
{frege/tools}.fr{$(TOOLSF1)}.class::
	$(FREGEC0) $<
# {frege/lib}.fr{$(LIBF)}.class::
#	$(FREGECC) $<
{frege/tools}.fr{$(TOOLSF)}.class::
	$(FREGECC) $<
{frege/prelude}.fr{$(PREL)}.class::
	$(FREGEC2) $<


sanitycheck:
	$(JAVA) -version


frege.mk: Makefile scripts/mkmk.pl
	perl scripts/mkmk.pl <Makefile >frege.mk

dist: fregec.jar
	perl scripts/mkdist.pl



fregec.jar: compiler $(DIR)/check1
	$(FREGECC)  -make  frege/StandardLibrary.fr
	jar  -cf    fregec.jar -C build frege
	jar  -uvfe  fregec.jar frege.compiler.Main
	cp fregec.jar fallback.jar

fregec7.jar:  savejava
	@echo The following will probably only work if you just made a compiler
	rm -rf build7
	mkdir build7
	@echo You can ignore the compiler warning.
	$(JAVAC) -J-Xmx1g -source 1.7 -target 1.7 -sourcepath save -d build7 \
	    save/frege/compiler/Main.java
	jar -cf   fregec7.jar -C build7 frege
	jar -uvfe fregec7.jar frege.compiler.Main
	@echo Looks good .... let us try to make the tools and library ... 
	$(JAVA) -Xmx1g -Xss4m -Dfrege.javac="javac -source 1.7 -target 1.7" -jar fregec7.jar -d build7 -nocp -fp build7 -make \
	    frege/StandardTools.fr frege/StandardLibrary.fr
	@echo Still running? Now we have it almost .... 
	cp frege/tools/yygenpar-fr frege/tools/YYgenparM-fr build7/frege/tools
	jar -cf   fregec7.jar -C build7 frege
	jar -uvfe fregec7.jar frege.compiler.Main
	cp fregec7.jar ../eclipse-plugin/lib/fregec.jar
 
fregec6.jar: fallback.jar savejava
	@echo The following will probably only work if you just made a fregec.jar
	@echo Adapting the sources for dumb old java6 ....
	cp frege/runtime/Concurrent.java6 save/frege/runtime/Concurrent.java
	cp frege/runtime/Runtime.java6    save/frege/runtime/Runtime.java
	cp frege/runtime/CompilerSupport.java6    save/frege/runtime/CompilerSupport.java
	rm -rf build6
	mkdir build6
	@echo You can ignore the compiler warning.
	$(JAVAC) -J-Xmx1g -source 1.6 -target 1.6 -sourcepath save -d build6 \
	    save/frege/compiler/Main.java
	jar -cf   fregec6.jar -C build6 frege
	jar -uvfe fregec6.jar frege.compiler.Main
	@echo Looks good .... let us try to make the tools and library ... 
	grep -v ForkJoin frege/StandardLibrary.fr >save/StandardLibrary.fr
	$(JAVA) -Xmx1g -Xss4m -Dfrege.javac="javac -source 1.6 -target 1.6" -jar fregec6.jar -d build6 -nocp -fp build6 -make \
	    frege/StandardTools.fr save/StandardLibrary.fr
	@echo Still running? Now we have it almost .... 
	cp frege/tools/yygenpar-fr frege/tools/YYgenparM-fr build6/frege/tools
	jar -cf   fregec6.jar -C build6 frege
	jar -uvfe fregec6.jar frege.compiler.Main
	@echo
	@echo !-------------- PLEASE NOTE ----------------------------------------------
	@echo !  The new compiler will itself generate java6 classes if run in a JDK6.  
	@echo !  Unfortunately, the Java 6 compiler may not understand proper Java.     
	@echo !  To avoid those problems, use this JAR always thus:                     
	@echo !      java  -Dfrege.javac=\"javac -source 1.6 -target 1.6\" -jar fregec6.jar ...  
	@echo !  where javac is a JDK-7 compiler!                                       
	@echo !-------------------------------------------------------------------------
	@echo
	
#
#	Avoid recompilation of everything, just remake the compiler with itself and jar it.
#	One should have a fallback.jar, just in case ....
#
test-jar: fallback.jar
	$(FREGEC2) -make frege.compiler.Main
	$(FREGEC2) -make frege.ide.Utilities
	jar  -cf    fregec.jar -C build frege
	jar  -uvfe  fregec.jar frege.compiler.Main
	cp fregec.jar  ../eclipse-plugin/lib/fregec.jar


$(DIR)/check1: $(DIR)/PreludeProperties.class
	$(JAVA) -Xss1m -cp build frege.PreludeProperties && echo Prelude Properties checked >$(DIR)/check1



$(DIR)/PreludeProperties.class:  frege/PreludeProperties.fr
	$(FREGECC) -make  frege/PreludeProperties.fr

# 	$(TOOLSF)/Doc.class $(TOOLSF)/YYgen.class $(TOOLSF)/LexConvt.class
tools: $(COMPF)/Main.class
	$(FREGECC) -make  frege/StandardTools.fr
#
# final compiler
#
compiler: compiler2 $(COMPF)/Grammar.class $(COMPF)/Main.class tools
	cp frege/tools/yygenpar-fr frege/tools/YYgenparM-fr build/frege/tools
	@echo Compiler ready

$(COMPF)/grammar/Frege.class: frege/compiler/grammar/Frege.fr $(COMPF)/common/Desugar.class
	$(FREGEC2) -v frege/compiler/grammar/Frege.fr
frege/compiler/grammar/Frege.fr: frege/compiler/grammar/Frege.y
	@echo 1 shift/reduce conflict expected
	$(YACC) -v frege/compiler/grammar/Frege.y
	$(FREGE) -cp fregec.jar frege.tools.YYgen -m State  frege/compiler/grammar/Frege.fr
	$(FREGE) -cp fregec.jar frege.tools.LexConvt frege/compiler/grammar/Frege.fr
	rm -f frege/compiler/grammar/Frege.fr.bak
$(COMPF)/Grammar.class: frege/compiler/Grammar.fr $(COMPF)/GUtil.class
	$(FREGEC2) -v frege/compiler/Grammar.fr
frege/compiler/Grammar.fr: frege/compiler/Grammar.y
	@echo 1 shift/reduce conflict expected
	$(YACC) -v frege/compiler/Grammar.y
	$(FREGE) -cp fregec.jar frege.tools.YYgen -m State  frege/compiler/Grammar.fr
	$(FREGE) -cp fregec.jar frege.tools.LexConvt frege/compiler/Grammar.fr
	rm -f frege/compiler/Grammar.fr.bak
frege/Version.fr: .git/index
	perl scripts/mkversion.pl >frege/Version.fr
$(COMPF)/Scanner.class: $(DIR)/Prelude.class frege/compiler/Scanner.fr
	$(FREGEC2)  -make frege.compiler.Scanner
$(COMPF)/common/Desugar.class: frege/compiler/common/Desugar.fr $(DIR)/Prelude.class
	$(FREGEC2)  -make frege/compiler/common/Desugar.fr
$(COMPF)/GUtil.class: frege/compiler/GUtil.fr $(DIR)/Prelude.class
	$(FREGEC2)  -make frege/compiler/GUtil.fr
$(COMPF)/Main.class: $(DIR)/Prelude.class frege/compiler/Main.fr frege/Version.fr
	$(FREGEC2)  -make frege.compiler.Main
$(DIR)/Prelude.class: $(COMPF2)/Main.class $(PRELUDE)
	rm -rf $(DIR)
	cd build && mkdir frege
	$(JAVAC) -d build frege/runtime/*.java
	$(FREGEC2)  $(PRELUDE)
	$(FREGEC2)  -make  frege.Prelude

compiler2: $(COMPF2)/Main.class
	@echo stage 2 compiler ready


$(COMPF2)/Main.class: $(DIR2)/Prelude.class frege/Version.fr
	$(FREGEC1) -v -make frege.compiler.Main
$(DIR2)/Prelude.class: $(RUNTIME) $(COMPF1)/Main.class frege/Prelude.fr $(PRELUDE)
	rm -rf $(COMPF2)
	rm -rf $(DIR2)
	$(FREGEC1)  $(PRELUDE)
	$(FREGEC1)  -make frege.Prelude


SOURCES  =      $(COMPS)/Scanner.fr   $(COMPS)/Classtools.fr \
		$(COMPS)/types/Positions.fr $(COMPS)/enums/Flags.fr \
		$(COMPS)/types/Global.fr      $(COMPS)/Utilities.fr \
		$(COMPS)/GUtil.fr \
		$(COMPS)/Main.fr      $(COMPS)/Grammar.fr   $(COMPS)/Grammar.y \
		$(COMPS)/Fixdefs.fr   $(COMPS)/Import.fr    $(COMPS)/Enter.fr \
		$(COMPS)/TAlias.fr    \
		$(COMPS)/Javatypes.fr $(COMPS)/Kinds.fr \
		$(COMPS)/Transdef.fr  $(COMPS)/Classes.fr \
		$(COMPS)/Transform.fr \
		$(COMPS)/tc/Methods.fr $(COMPS)/tc/Patterns.fr \
		$(COMPS)/Typecheck.fr \
		$(COMPS)/tc/Util.fr \
		$(COMPS)/gen/Util.fr  $(COMPS)/gen/Const.fr \
		$(COMPS)/gen/Bindings.fr $(COMPS)/gen/Match.fr \
		$(COMPS)/GenMeta.fr   $(COMPS)/GenJava7.fr


CLASSES  =       $(COMPF1)/Scanner.class   $(COMPF1)/Classtools.class \
		$(COMPF1)/types/Positions.class \
		$(COMPF1)/types/Global.class      $(COMPF1)/Utilities.class \
		$(COMPF1)/GUtil.class	$(COMPF1)/Grammar.class \
		$(COMPF1)/Fixdefs.class   $(COMPF1)/Import.class \
		$(COMPF1)/gen/Const.class  $(COMPF1)/gen/Util.class \
		$(COMPF1)/Enter.class \
		$(COMPF1)/Javatypes.class $(COMPF1)/Kinds.class $(COMPF1)/Transdef.class \
		$(COMPF1)/tc/Util.class   \
		$(COMPF1)/TAlias.class    $(COMPF1)/Classes.class \
		$(COMPF1)/tc/Methods.class $(COMPF1)/tc/Patterns.class \
		$(COMPF1)/Typecheck.class $(COMPF1)/Transform.class \
		$(COMPF1)/gen/Bindings.class $(COMPF1)/gen/Match.class \
		$(COMPF1)/GenMeta.class   $(COMPF1)/GenJava7.class

#
# GNU make apparently does not understand our meta rules
#
$(PREL)/PreludeBase.class: frege/prelude/PreludeBase.fr
	$(FREGECC) $?
$(PREL)/PreludeNative.class: $(PREL)/PreludeBase.class frege/prelude/PreludeNative.fr
	$(FREGECC) frege/prelude/PreludeNative.fr
$(PREL)/PreludeList.class: $(PREL)/PreludeBase.class frege/prelude/PreludeList.fr
	$(FREGECC) frege/prelude/PreludeList.fr
$(PREL)/PreludeText.class: $(PREL)/PreludeList.class frege/prelude/PreludeText.fr
	$(FREGECC) frege/prelude/PreludeText.fr
$(DATA1)/TreeMap.class: frege/data/TreeMap.fr
	$(FREGEC0) -make $?
$(CONTROL1)/Monoid.class: frege/control/Monoid.fr
	$(FREGEC0) $?
$(COMPF1)/tc/Patterns.class: frege/compiler/tc/Patterns.fr
	$(FREGEC0) -make $?
$(COMPF1)/tc/Methods.class: frege/compiler/tc/Methods.fr
	$(FREGEC0) -make $?
$(COMPF1)/Classtools.class: frege/compiler/Classtools.fr
	$(FREGEC0) -make $?
$(COMPF1)/BaseTypes.class: frege/compiler/BaseTypes.fr
	$(FREGEC0) $?
$(COMPF1)/Utilities.class: $(COMPF1)/BaseTypes.class $(COMPF1)/Classtools.class $(COMPF1)/types/Global.class $(COMPF1)/Nice.class $(COMPS)/Utilities.fr
	$(FREGEC0) $(COMPS)/Utilities.fr
$(COMPF1)/GUtil.class: frege/compiler/GUtil.fr
	$(FREGEC0)  -make $?
$(COMPF1)/types/Global.class: 	$(COMPF1)/BaseTypes.class $(COMPS)/types/Global.fr
	$(FREGEC0)  -make $(COMPS)/types/Global.fr
$(COMPF1)/Nice.class: 	$(COMPS)/Nice.fr $(LIBF1)/PP.class $(COMPF1)/types/Global.class $(DATA1)/List.class
	$(FREGEC0) $(COMPS)/Nice.fr
$(COMPF1)/Fixdefs.class: $(COMPS)/Fixdefs.fr
	$(FREGEC0) $?
$(COMPF1)/Import.class: $(DATA1)/Tuples.class $(COMPS)/Import.fr
	$(FREGEC0) $(COMPS)/Import.fr
$(COMPF1)/Enter.class: $(COMPS)/Enter.fr
	$(FREGEC0) $?
$(COMPF1)/Kinds.class: $(COMPS)/Kinds.fr
	$(FREGEC0) $?
$(COMPF1)/Transdef.class: $(COMPS)/Transdef.fr
	$(FREGEC0) $?
$(COMPF1)/Javatypes.class: $(COMPS)/Javatypes.fr
	$(FREGEC0) $?
$(COMPF1)/tc/Util.class: $(COMPS)/tc/Util.fr
	$(FREGEC0) $?
$(COMPF1)/TAlias.class: $(COMPS)/TAlias.fr
	$(FREGEC0) $?
$(COMPF1)/Classes.class: $(COMPS)/Classes.fr
	$(FREGEC0) $?
$(COMPF1)/Transform.class: $(COMPS)/Transform.fr
	$(FREGEC0) $?
$(COMPF1)/Typecheck.class: $(COMPS)/Typecheck.fr
	$(FREGEC0) $?
$(COMPF1)/GenMeta.class: $(COMPS)/GenMeta.fr
	$(FREGEC0) $?
$(COMPF1)/GenJava7.class: $(COMPS)/GenJava7.fr
	$(FREGEC0) -make $?
$(COMPF1)/gen/Util.class: $(COMPS)/gen/Util.fr
	$(FREGEC0) $?
$(COMPF1)/gen/Match.class: $(COMPS)/gen/Match.fr
	$(FREGEC0) $?
$(COMPF1)/gen/Const.class: $(COMPS)/gen/Const.fr
	$(FREGEC0) $?
$(COMPF1)/gen/Bindings.class: $(COMPS)/gen/Bindings.fr
	$(FREGEC0) $?
$(COMPF1)/DocUtils.class: $(COMPS)/DocUtils.fr
	$(FREGEC0) -make $?
$(COMPF1)/EclipseUtil.class: $(COMPS)/EclipseUtil.fr
	$(FREGEC0) -make $?
$(LIBF1)/Random.class: frege/lib/Random.fr
	$(FREGEC0) $?
$(LIBF1)/PP.class: frege/lib/PP.fr
	$(FREGEC0) $?
$(LIBF1)/QuickCheck.class: $(LIBF1)/Random.class $(DATA1)/List.class frege/lib/QuickCheck.fr
	$(FREGEC0) frege/lib/QuickCheck.fr
$(DATA1)/List.class: frege/data/List.fr
	$(FREGEC0) frege/data/List.fr
$(DATA1)/Tuples.class: frege/data/Tuples.fr
	$(FREGEC0) -make frege/data/Tuples.fr
$(DATA1)/Bits.class: frege/data/Bits.fr
	$(FREGEC0) -make frege/data/Bits.fr
$(DATA1)/Maybe.class: frege/data/Maybe.fr
	$(FREGEC0) frege/data/Maybe.fr
$(LIBF1)/ForkJoin.class: frege/lib/ForkJoin.fr
	$(FREGEC0) $?

PRE1 = $(DIR1)/Prelude.class $(DATA1)/TreeMap.class $(DATA1)/Bits.class

compiler1: $(RUNTIME)  $(DIR1)/check1  $(LIBF1)/PP.class $(COMPF1)/Grammar.class $(COMPF1)/Main.class
	@echo stage 1 compiler ready

$(COMPF1)/Grammar.class: frege/compiler/Grammar.fr
	$(FREGEC0)  -make frege.compiler.Grammar
$(COMPF1)/Scanner.class: frege/compiler/Scanner.fr
	$(FREGEC0)  -make frege.compiler.Scanner
$(COMPF1)/Main.class : $(PRE1) $(SOURCES) frege/Version.fr
	$(FREGEC0)  -make frege.compiler.Main
$(DIR1)/Prelude.class: $(SPRELUDE) frege/Prelude.fr
	rm -rf $(COMPF1)
	rm -rf $(DIR1)
	$(FREGEC0) $(SPRELUDE)
	$(FREGEC0)  -make frege.Prelude
$(DIR1)/PreludeProperties.class: frege/PreludeProperties.fr
	$(FREGEC0) -make frege/PreludeProperties.fr
$(DIR1)/check1: $(PRE1) $(DIR1)/PreludeProperties.class
	$(JAVA) -Xss1m -cp build afrege.PreludeProperties && echo Prelude Properties checked >$(DIR1)/check1




runtime:
	mkdir -p build
	$(JAVAC) -d build frege/runtime/*.java
	@echo Runtime is complete.



#
#   Documentation
#


doc/index.html: $(RUNTIME)


docu: fregec.jar
	javadoc -private -sourcepath . -d $(DOC) -encoding UTF-8 frege.runtime
	$(JAVA) -cp fregec.jar frege.tools.Doc -v -d $(DOC) -x frege.compiler,frege.runtime,frege.S,frege.V,frege.PreludePr fregec.jar


#
#   Difference between 2 compilers
#   The output of the first must have been stored in "save" (see "savejava")
#   Compares all java files in save/frege with those in build/frege
#
diffs:
	diff -b -r -x "*.class" -I "This code was generated with the frege compiler version" -I "^ +source=" save  build

savejava:
	perl scripts/savejava.pl
