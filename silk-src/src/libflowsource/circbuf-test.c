/*
** Copyright (C) 2009-2016 by Carnegie Mellon University.
**
** @OPENSOURCE_HEADER_START@
**
** Use of the SILK system and related source code is subject to the terms
** of the following licenses:
**
** GNU General Public License (GPL) Rights pursuant to Version 2, June 1991
** Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
**
** NO WARRANTY
**
** ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER
** PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY
** PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN
** "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY
** KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT
** LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE,
** MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE
** OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT,
** SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY
** TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF
** WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES.
** LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF
** CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON
** CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE
** DELIVERABLES UNDER THIS LICENSE.
**
** Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie
** Mellon University, its trustees, officers, employees, and agents from
** all claims or demands made against them (and any related losses,
** expenses, or attorney's fees) arising out of, or relating to Licensee's
** and/or its sub licensees' negligent use or willful misuse of or
** negligent conduct or willful misconduct regarding the Software,
** facilities, or other rights or assistance granted by Carnegie Mellon
** University under this License, including, but not limited to, any
** claims of product liability, personal injury, death, damage to
** property, or violation of any laws or regulations.
**
** Carnegie Mellon University Software Engineering Institute authored
** documents are sponsored by the U.S. Department of Defense under
** Contract FA8721-05-C-0003. Carnegie Mellon University retains
** copyrights in all material produced under this contract. The U.S.
** Government retains a non-exclusive, royalty-free license to publish or
** reproduce these documents, or allow others to do so, for U.S.
** Government purposes only pursuant to the copyright license under the
** contract clause at 252.227.7013.
**
** @OPENSOURCE_HEADER_END@
*/

/*
**  Small application to test the circbuf library.
**
*/

#include <silk/silk.h>

RCSIDENT("$SiLK: circbuf-test.c 71c2983c2702 2016-01-04 18:33:22Z mthomas $");

#include <silk/skthread.h>
#include <silk/utils.h>
#include "circbuf.h"


/* LOCAL DEFINES AND TYPEDEFS */

/* where to write usage */
#define USAGE_FH stderr

/* size of items in the circbuf */
#define ITEM_SIZE 1024

/* number of items in the circbuf */
#define ITEM_COUNT 1024

/* default number of times to run with timestamps */
#define VERBOSE_COUNT 5

/* default total number of times to run */
#define TOTAL_COUNT 2048


/* LOCAL VARIABLE DEFINITIONS */

/* actual number of verbose runs */
static unsigned int verbose_count = VERBOSE_COUNT;

/* actual number of total runs */
static unsigned int total_count = TOTAL_COUNT;

/* variables to handle shutdown */
static pthread_mutex_t shutdown_mutex;
static pthread_cond_t shutdown_ok;


/* FUNCTION DEFINITIONS */

/*
 *  appUsageLong();
 *
 *    Print complete usage information to USAGE_FH.  Pass this
 *    function to skOptionsSetUsageCallback(); skOptionsParse() will
 *    call this funciton and then exit the program when the --help
 *    option is given.
 */
static void
appUsageLong(
    void)
{
#define USAGE_MSG_HELPER2(m_tot, m_verb)                                \
    ("[TOTAL_RUNS [VERBOSE_RUNS]]\n"                                    \
     "\tSmall application to test circular buffer code.\n"              \
     "\tRuns TOTAL_RUN compete runs (default " #m_tot "),\n"            \
     "\tthe first VERBOSE_RUNS (default " #m_verb ") of which are verbose.\n")

#define USAGE_MSG_HELPER1(m_tot, m_verb) USAGE_MSG_HELPER2(m_tot, m_verb)

#define USAGE_MSG USAGE_MSG_HELPER1(TOTAL_COUNT, VERBOSE_COUNT)

    FILE *fh = USAGE_FH;

    skAppStandardUsage(fh, USAGE_MSG, NULL, NULL);
}

/*
 *    Entry point for thread to put stuff into the circbuf.
 */
static void *
writer(
    void               *arg)
{
    sk_circbuf_t *cbuf = (sk_circbuf_t*)arg;
    unsigned int count = 0;
    struct timeval t_pre;
    struct timeval t_post;
    uint32_t buf_count = 0;
    uint8_t *h = NULL;
    int rv;

    for ( ; count < verbose_count; ++count) {
        gettimeofday(&t_pre, NULL);
        rv = skCircBufGetWriterBlock(cbuf, &h, &buf_count);
        gettimeofday(&t_post, NULL);
        if (rv != SK_CIRCBUF_OK) {
            skAppPrintErr("Stopped writing after %u puts", count);
            return NULL;
        }
        memset(h, count, ITEM_SIZE);
        memcpy(h, &count, sizeof(count));
        fprintf(stderr, ("Writer   %5u %5" PRIu32 " %17ld.%06u  %4ld.%06u\n"),
                count, buf_count,
                t_pre.tv_sec % 3600, (unsigned int)t_pre.tv_usec,
                t_post.tv_sec % 3600, (unsigned int)t_post.tv_usec);
        sleep(1);
    }

    for ( ; count < 1 + total_count; ++count) {
        if (skCircBufGetWriterBlock(cbuf, &h, NULL) != SK_CIRCBUF_OK) {
            skAppPrintErr("Stopped writing after %u puts", count);
            return NULL;
        }
        memset(h, count, ITEM_SIZE);
        memcpy(h, &count, sizeof(count));
    }

    /* we've written all we need to write.  continue to write until
     * the circbuf is destroyed  */

    while (skCircBufGetWriterBlock(cbuf, &h, NULL) == SK_CIRCBUF_OK) {
        memset(h, count, ITEM_SIZE);
        memcpy(h, &count, sizeof(count));
        ++count;
    }

    fprintf(stderr, "Final put count = %u\n", count);

    return NULL;
}


/*
 *    Entry point for thread to get stuff from the circbuf.
 */
static void *
reader(
    void               *arg)
{
    uint8_t cmpbuf[ITEM_SIZE];
    sk_circbuf_t *cbuf = (sk_circbuf_t*)arg;
    unsigned int count = 0;
    struct timeval t_pre;
    struct timeval t_post;
    uint32_t buf_items = 0;
    uint8_t *t = NULL;
    int rv;
    int i;

    for ( ; count < verbose_count; ++count) {
        memset(cmpbuf, count, sizeof(cmpbuf));
        memcpy(cmpbuf, &count, sizeof(count));
        gettimeofday(&t_pre, NULL);
        rv = skCircBufGetReaderBlock(cbuf, &t, &buf_items);
        gettimeofday(&t_post, NULL);
        if (rv != SK_CIRCBUF_OK) {
            skAppPrintErr("Stopped reading after %u gets", count);
            return NULL;
        }
        if (0 != memcmp(t, cmpbuf, sizeof(cmpbuf))) {
            skAppPrintErr("Invalid data for count %u", count);
        }
        fprintf(stderr, ("Reader   %5u %5" PRIu32 " %4ld.%06u  %4ld.%06u\n"),
                count, buf_items,
                t_pre.tv_sec % 3600, (unsigned int)t_pre.tv_usec,
                t_post.tv_sec % 3600, (unsigned int)t_post.tv_usec);
    }

    for (i = 1; i >= 0; --i) {

        for ( ; (count < (total_count >> i)); ++count) {
            if (skCircBufGetReaderBlock(cbuf, &t, NULL) != SK_CIRCBUF_OK) {
                skAppPrintErr("Stopped reading after %u gets", count);
                return NULL;
            }
            memset(cmpbuf, count, sizeof(cmpbuf));
            memcpy(cmpbuf, &count, sizeof(count));
            if (0 != memcmp(t, cmpbuf, sizeof(cmpbuf))) {
                skAppPrintErr("Invalid data for count %u", count);
            }
        }

        /* give the writer time to fill up the circbuf */
        if (i == 1) {
            sleep(4);
        }
    }

    /* we've read all we need to read.  let the main program know it
     * can shutdown. */
    pthread_mutex_lock(&shutdown_mutex);
    pthread_cond_broadcast(&shutdown_ok);
    pthread_mutex_unlock(&shutdown_mutex);

    while (skCircBufGetReaderBlock(cbuf, &t, NULL) == SK_CIRCBUF_OK) {
        memset(cmpbuf, count, sizeof(cmpbuf));
        memcpy(cmpbuf, &count, sizeof(count));
        if (0 != memcmp(t, cmpbuf, sizeof(cmpbuf))) {
            skAppPrintErr("Invalid data for count %u", count);
        }
        ++count;
    }

    fprintf(stderr, "Final get count = %u\n", count);

    return NULL;
}


int main(int argc, char **argv)
{
    SILK_FEATURES_DEFINE_STRUCT(features);
    pthread_t read_thrd;
    pthread_t write_thrd;
    sk_circbuf_t *cbuf;
    uint32_t tmp32;
    int arg_index;
    int rv;

    skAppRegister(argv[0]);
    skAppVerifyFeatures(&features, NULL);
    skOptionsSetUsageCallback(&appUsageLong);

    arg_index = skOptionsParse(argc, argv);
    if (arg_index < 0) {
        skAppUsage();
    }
    if (arg_index < argc) {
        rv = skStringParseUint32(&tmp32, argv[arg_index], 0, INT32_MAX);
        if (rv) {
            skAppPrintErr("Invalid total number of runs '%s': %s",
                          argv[arg_index], skStringParseStrerror(rv));
            exit(EXIT_FAILURE);
        }
        total_count = (unsigned int)tmp32;
        ++arg_index;
    }
    if (arg_index < argc) {
        rv = skStringParseUint32(&tmp32, argv[arg_index], 0, INT32_MAX);
        if (rv) {
            skAppPrintErr("Invalid number of verbose runs '%s': %s",
                          argv[arg_index], skStringParseStrerror(rv));
            exit(EXIT_FAILURE);
        }
        verbose_count = (unsigned int)tmp32;
        ++arg_index;
    }
    if (arg_index < argc) {
        skAppPrintErr("Maximum of two arguments permitted");
        exit(EXIT_FAILURE);
    }

    if (verbose_count > total_count) {
        verbose_count = total_count;
    }

    pthread_mutex_init(&shutdown_mutex, NULL);
    pthread_cond_init(&shutdown_ok, NULL);

    /* should fail due to item_size == 0 */
    rv = skCircBufCreate(&cbuf, 0, 1);
    if (SK_CIRCBUF_E_BAD_PARAM != rv) {
        skAppPrintErr("FAIL");
        exit(EXIT_FAILURE);
    }

    /* should fail due to item_count == 0 */
    rv = skCircBufCreate(&cbuf, 1, 0);
    if (SK_CIRCBUF_E_BAD_PARAM != rv) {
        skAppPrintErr("FAIL");
        exit(EXIT_FAILURE);
    }

    /* should fail due to item_size too large */
    rv = skCircBufCreate(&cbuf, INT32_MAX, 3);
    if (SK_CIRCBUF_E_BAD_PARAM != rv) {
        skAppPrintErr("FAIL");
        exit(EXIT_FAILURE);
    }

    /* should succeed */
    rv = skCircBufCreate(&cbuf, ITEM_SIZE, ITEM_COUNT);
    if (SK_CIRCBUF_OK != rv) {
        skAppPrintErr("FAIL");
        exit(EXIT_FAILURE);
    }

    pthread_mutex_lock(&shutdown_mutex);

    skthread_create("reader", &read_thrd, &reader, cbuf);

    skthread_create("writer", &write_thrd, &writer, cbuf);

    pthread_cond_wait(&shutdown_ok, &shutdown_mutex);
    pthread_mutex_unlock(&shutdown_mutex);

    skCircBufStop(cbuf);

    pthread_join(write_thrd, NULL);
    pthread_join(read_thrd, NULL);

    skCircBufDestroy(cbuf);

    skAppUnregister();

    return 0;
}


/*
** Local Variables:
** mode:c
** indent-tabs-mode:nil
** c-basic-offset:4
** End:
*/
