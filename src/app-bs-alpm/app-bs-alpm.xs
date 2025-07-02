#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

MODULE = app-bs-alpm		PACKAGE = app-bs-alpm		

INCLUDE: const-xs.inc
