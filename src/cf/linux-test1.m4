# AC_TRY_KBUILD26([INCLUDES], [FUNCTION-BODY],
#                 [ACTION-IF-SUCCESS], [ACTION-IF-FAILURE])
#
AC_DEFUN([AC_TRY_KBUILD26],[  rm -fr conftest.dir
  if test "x$ac_linux_kbuild_requires_extra_cflags" = "xyes" ; then
    CFLAGS_PREFIX='EXTRA_'
  fi
  if mkdir conftest.dir &&
    cat >conftest.dir/Makefile <<_ACEOF &&
${CFLAGS_PREFIX}CFLAGS += $CPPFLAGS

obj-m += conftest.o
_ACEOF
    cat >conftest.dir/conftest.c <<\_ACEOF &&
/* confdefs.h */
_ACEOF
    cat confdefs.h >>conftest.dir/conftest.c &&
    cat >>conftest.dir/conftest.c <<_ACEOF &&
/* end confdefs.h */
#include <linux/module.h>
$1

void conftest(void)
{ 
$2
} 

MODULE_LICENSE("http://www.openafs.org/dl/license10.html");
_ACEOF
    echo make -C $LINUX_KERNEL_BUILD M=$SRCDIR_PARENT/conftest.dir modules KBUILD_VERBOSE=1 >&AS_MESSAGE_LOG_FD &&
    make -C $LINUX_KERNEL_BUILD M=$SRCDIR_PARENT/conftest.dir modules KBUILD_VERBOSE=1 >&AS_MESSAGE_LOG_FD 2>conftest.err &&
    ! grep -i "^WARNING: .* undefined!$" conftest.err >/dev/null 2>&1
    then [$3]
    else
      sed '/^ *+/d' conftest.err >&AS_MESSAGE_LOG_FD
      echo "$as_me: failed using Makefile:" >&AS_MESSAGE_LOG_FD
      sed 's/^/| /' conftest.dir/Makefile >&AS_MESSAGE_LOG_FD
      echo "$as_me: and program was:" >&AS_MESSAGE_LOG_FD
      sed 's/^/| /' conftest.dir/conftest.c >&AS_MESSAGE_LOG_FD
      [$4]
  fi; rm -fr conftest.err conftest.dir])

  
# AC_TRY_KBUILD24([INCLUDES], [FUNCTION-BODY],
#                 [ACTION-IF-SUCCESS], [ACTION-IF-FAILURE])
#
AC_DEFUN([AC_TRY_KBUILD24], [
  ac_save_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="-I$LINUX_KERNEL_PATH/include -D__KERNEL__ -Werror-implicit-function-declaration $CPPFLAGS"
  AC_TRY_COMPILE([
#include <linux/kernel.h>
$1], [$2], [$3], [$4])
  CPPFLAGS="$ac_save_CPPFLAGS"])


# AC_TRY_KBUILD([INCLUDES], [FUNCTION-BODY],
#               [ACTION-IF-SUCCESS], [ACTION-IF-FAILURE])
#
AC_DEFUN([AC_TRY_KBUILD], [
  if test $AFS_SYSKVERS -ge 26 ; then
    AC_TRY_KBUILD26([$1], [$2], [$3], [$4])
  else
    AC_TRY_KBUILD24([$1], [$2], [$3], [$4])
  fi])

AC_DEFUN([LINUX_KERNEL_COMPILE_WORKS], [
  AC_MSG_CHECKING([for linux kernel module build works])
  openafs_linux_patchlevel="`sed -n 's%PATCHLEVEL = %%p' $LINUX_KERNEL_PATH/Makefile`"
  if test "$openafs_linux_patchlevel" -ge 6; then
    openafs_lkcw_cmpop='<'; openafs_lkcw_testop='-lt'
  else
    openafs_lkcw_cmpop='>='; openafs_lkcw_testop='-ge'
  fi
  if test "`echo $AFS_SYSNAME | sed 's;.*linux-*;;'`" $openafs_lkcw_testop 26
  then
    openafs_lkcw_cmpop='lose; sysname and kernel path not consistent'
  fi
  AC_TRY_KBUILD(
[#include <linux/version.h>],
[/* sysname is $AFS_SYSNAME; kernel_path is $LINUX_KERNEL_PATH */
#if LINUX_VERSION_CODE $openafs_lkcw_cmpop KERNEL_VERSION(2,6,0)
lose
#endif
],:,AC_MSG_RESULT(no)
    AC_MSG_FAILURE([Fix problem or use --disable-kernel-module...]))
  AC_MSG_RESULT(yes)])

AC_DEFUN([LINUX_KBUILD_USES_EXTRA_CFLAGS], [
  AC_MSG_CHECKING([if linux kbuild requires EXTRA_CFLAGS])
  save_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS=-Wall
  AC_TRY_KBUILD(
[#include <linux/sched.h>
#include <linux/fs.h>],
    [],
    ac_linux_kbuild_requires_extra_cflags=no,
    ac_linux_kbuild_requires_extra_cflags=yes)
    CPPFLAGS="$save_CPPFLAGS"
    AC_MSG_RESULT($ac_linux_kbuild_requires_extra_cflags)])
