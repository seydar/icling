%% A Compiler Written in MATLAB
% * There is a compiler named xcom.
% * There is a traditional compiler theory course based on xcom.
% * The latest version is on the MATLAB File Exchange (# 20419).

%% Getting Started
% The file README.html in the mxcom directory gives a structured
% introduction to the compiler and course.

%% Running xcom
% Once you have the FX version unpacked into a directory
% you can compile and run a simple program in the X language:

xcom y:=1

%%
% The meaning of the X program 'y:=1' is 'assign integer 1 to variable y.
% Since the assignment is wasted (variable y is not subsequently used),
% xcom reports the final value of y as output.  The remaining details of
% the little language X are given in the X reference manual in the
% downloaded compiler+course.  X is intended as a minimal base language to
% which the compiler writing student will add whatever constructs are of
% interest.

%% xcom Flags
% The compiler comes with a comprehensive set of flags, mostly designed to
% produce intermediate output of the inner workings of xcom.  For instance,
% the Intel X86 machine language for a program can be dumped as follows

xcom -asmTrace y:=1

%%
% What you see is almost all prolog and epilog code
% (standard for any X program).  At byte 8 you can see the integer constant
% 1 being loaded into x86 register EAX, and at byte 13 you can see the move
% that puts the answer at offset 0 in the frame (where variable y is
% located).  Information about the flags can be see via the command

help xcom %#ok<MCHLP>
