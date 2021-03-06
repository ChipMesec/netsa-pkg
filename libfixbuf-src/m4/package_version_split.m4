AC_DEFUN([PACKAGE_VERSION_SPLIT],[
    PACKAGE_VERSION_MAJOR=`echo "$PACKAGE_VERSION"   | $SED 's/\([[^.]]*\).*/\1/'`
    PACKAGE_VERSION_MINOR=`echo "$PACKAGE_VERSION"   | $SED 's/[[^.]]*\.\([[^.]]*\).*/\1/'`
    PACKAGE_VERSION_RELEASE=`echo "$PACKAGE_VERSION" | $SED 's/[[^.]]*\.[[^.]]*\.\([[^.]]*\).*/\1/'`
    PACKAGE_VERSION_BUILD=`echo "$PACKAGE_VERSION"   | $SED 's/[[^.]]*\.[[^.]]*\.[[^.]]*\.\(.*\)/\1/'`
    if test "x$PACKAGE_VERSION_BUILD" = "x$PACKAGE_VERSION"; then
        PACKAGE_VERSION_BUILD="0"
    fi
    AC_SUBST(PACKAGE_VERSION_MAJOR)
    AC_SUBST(PACKAGE_VERSION_MINOR)
    AC_SUBST(PACKAGE_VERSION_RELEASE)
    AC_SUBST(PACKAGE_VERSION_BUILD)
])
