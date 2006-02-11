"""
Base class for Jacobians of curves
"""

#*******************************************************************************
#  Copyright (C) 2005 William Stein
#  Distributed under the terms of the GNU General Public License (GPL)
#                  http://www.gnu.org/licenses/
#*******************************************************************************

from sage.rings.all import is_Field
from sage.schemes.generic.scheme import Scheme, is_Scheme

def is_Jacobian(X):
    return isinstance(X, Jacobian)

class Jacobian(Scheme):
    def __init__(self, C):
        if not is_Scheme(C):
            raise TypeError, "C (=%s) must be a scheme."%C
        # This was broken for curves over number fields:
        # if C.dimension() != 1:
        #     raise ValueError, "C (=%s) must have dimension 1."%C
        if not is_Field(C.base_ring()):
            raise TypeError, "C (=%s) must be defined over a field."%C
        self.__curve = C
        Scheme.__init__(self, C.base_scheme())

    def _repr_(self):
        return "Jacobian of %s"%self.__curve

    def _point_morphism_class(self):
        raise NotImplementedError

    def curve(self):
        """
        The curve that this is the Jacobian of.
        """
        return self.__curve
