/*
 * synergy -- mouse and keyboard sharing utility
 * Copyright (C) 2002 Chris Schoeneman
 * 
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * found in the file COPYING that should have accompanied this file.
 * 
 * This package is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include "CClientProxy1_2.h"
#include "CProtocolUtil.h"
#include "CLog.h"

//
// CClientProxy1_1
//

CClientProxy1_2::CClientProxy1_2(const CString& name, IStream* stream) :
	CClientProxy1_1(name, stream)
{
	// do nothing
}

CClientProxy1_2::~CClientProxy1_2()
{
	// do nothing
}

void
CClientProxy1_2::mouseRelativeMove(SInt32 xRel, SInt32 yRel)
{
	LOG((CLOG_DEBUG2 "send mouse relative move to \"%s\" %d,%d", getName().c_str(), xRel, yRel));
	CProtocolUtil::writef(getStream(), kMsgDMouseRelMove, xRel, yRel);
}
