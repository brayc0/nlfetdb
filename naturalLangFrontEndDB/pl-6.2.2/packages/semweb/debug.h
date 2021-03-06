/*  Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@cs.vu.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 2002-2010, University of Amsterdam
			      VU University Amsterdam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301  USA
*/

#ifndef DEBUG_H_INCLUDED
#define DEBUG_H_INCLUDED

#define O_DEBUG 1

#ifdef O_DEBUG
int		rdf_debuglevel();
foreign_t	rdf_debug(term_t level);

#define DEBUG(n, g) if ( rdf_debuglevel() >= (n) ) { g; }
#else
#define DEBUG(n, g) ((void)0);
#endif

#ifdef O_SECURE
#define SECURE(g) g
#else
#define SECURE(g) (void)0
#endif

#endif /*DEBUG_H_INCLUDED*/
