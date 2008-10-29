/*
 * Copyright (c) 2008 Kernel Drivers, LLC.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice,
 *   this list of conditions and the following disclaimer in the
 *   documentation
 *   and/or other materials provided with the distribution.
 * - Neither the name of Kernel Drivers, LLC nor the names of its
 *   contributors may be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission from Kernel Drivers, LLC.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
// File: AFSFlushBuffers.cpp
//

#include "AFSCommon.h"

NTSTATUS
AFSFlushBuffers( IN PDEVICE_OBJECT DeviceObject,
                 IN PIRP Irp)
{

    NTSTATUS           ntStatus = STATUS_SUCCESS;
    IO_STACK_LOCATION *pIrpSp = IoGetCurrentIrpStackLocation( Irp);
    PFILE_OBJECT       pFileObject = pIrpSp->FileObject;
    AFSFcb            *pFcb = (AFSFcb *)pFileObject->FsContext;
    AFSCcb            *pCcb = (AFSCcb *)pFileObject->FsContext2;
    IO_STATUS_BLOCK    iosb = {0};

    pIrpSp = IoGetCurrentIrpStackLocation( Irp);

    __Enter 
    {
        if (pFcb->Header.NodeTypeCode == AFS_ROOT_FCB ||
            pFcb->Header.NodeTypeCode == AFS_ROOT_ALL ) 
        {

            //
            // Do we need to do a full flush here?
            //
            try_return( ntStatus = STATUS_SUCCESS);

        }
        else if (pFcb->Header.NodeTypeCode != AFS_FILE_FCB)
        {
            //
            // Nothing to flush Everything but files are write through
            //
            try_return( ntStatus = STATUS_INVALID_PARAMETER);
        }
        //
        // The flush consists of two parts.  We firstly flush our
        // cache (if we have one), then we tell the service to write
        // to the remote server
        //
        __try
        {
            CcFlushCache( &pFcb->NPFcb->SectionObjectPointers, NULL, 0, &iosb);
        }
        __except( AFSExceptionFilter( GetExceptionCode(), GetExceptionInformation()) )
        {
        
            try_return( ntStatus = GetExceptionCode());
        }
        if (!NT_SUCCESS( iosb.Status )) 
        {
            try_return( ntStatus = iosb.Status );
        }
        //
        // Now, flush to the server - if there is stuff to do
        //
        ntStatus = AFSFlushExtents( pFcb );

try_exit:

        AFSCompleteRequest( Irp, ntStatus);
    }

    return ntStatus;
}
