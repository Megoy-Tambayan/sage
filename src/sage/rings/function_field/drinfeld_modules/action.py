r"""
The module action induced by a Drinfeld module

This module provides the class
:class:`sage.rings.function_field.drinfeld_module.action.DrinfeldModuleAction`.

AUTHORS:

- Antoine Leudière (2022-04)
"""

# *****************************************************************************
#        Copyright (C) 2022 Antoine Leudière <antoine.leudiere@inria.fr>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#                   http://www.gnu.org/licenses/
# *****************************************************************************

from sage.categories.action import Action
from sage.misc.latex import latex
from sage.rings.function_field.drinfeld_modules.drinfeld_module import DrinfeldModule


class DrinfeldModuleAction(Action):
    r"""
    This class represents the module action induced by a Drinfeld
    module.

    Let `\phi` be a Drinfeld module with base `\gamma: \mathbb{F}_q[X]
    \to K`. Let `L/K` be a field extension, let `x \in L`, let `a` be a
    function ring element; the action is defined as `(a, x) \mapsto
    \phi_a(x)`.

    .. NOTE::

        In this implementation, `L` is `K`.

    The user should never explicitly instantiate the class
    `DrinfeldModuleAction`.

    INPUT: the Drinfeld module

    EXAMPLES::

        sage: Fq.<z2> = GF(11)
        sage: FqX.<X> = Fq[]
        sage: K.<z> = Fq.extension(2)
        sage: phi = DrinfeldModule(FqX, [z, 0, 0, 1])
        sage: action = phi.action()
        sage: action
        Action on Finite Field in z of size 11^2 over its base induced by Drinfeld module defined by X |--> t^3 + z over base Finite Field in z of size 11^2 over its base

    The action on elements is computed as follows::

        sage: P = X + 1
        sage: a = z
        sage: action(P, a)
        ...
        4*z + 2
        sage: action(0, K.random_element())
        0
        sage: action(FqX.random_element(), 0)
        0

    Finally, given a Drinfeld module action, it is easy to recover the
    corresponding Drinfeld module::

        sage: action.drinfeld_module() is phi
        True
    """

    def __init__(self, drinfeld_module):
        """
        Initialize ``self``.

        INPUT: the Drinfeld module

        TESTS::

            sage: Fq.<z2> = GF(11)
            sage: FqX.<X> = Fq[]
            sage: K.<z> = Fq.extension(2)
            sage: phi = DrinfeldModule(FqX, [z, 0, 0, 1])
            sage: action = phi.action()
            sage: action._drinfeld_module is phi
            True
            sage: action._base_ring is phi.base()
            True
        """
        if not isinstance(drinfeld_module, DrinfeldModule):
            raise TypeError('input must be a DrinfeldModule')
        self._drinfeld_module = drinfeld_module
        self._base_ring = drinfeld_module.base()
        super().__init__(drinfeld_module.function_ring(), self._base_ring)

    def _act_(self, pol, x):
        r"""
        Return the action of ``pol`` on ``x``.

        INPUT:

        - ``pol`` -- a function ring element
        - ``x`` -- an element in the field acted upon

        OUTPUT: an element in the base codomain

        EXAMPLES::

            sage: Fq.<z2> = GF(11)
            sage: FqX.<X> = Fq[]
            sage: K.<z> = Fq.extension(2)
            sage: phi = DrinfeldModule(FqX, [z, 0, 0, 1])
            sage: action = phi.action()
            sage: P = X + 1
            sage: a = z
            sage: action(P, a)
            4*z + 2
            sage: action(0, K.random_element())
            0
            sage: action(FqX.random_element(), 0)
            0
        """
        if pol not in self._drinfeld_module.function_ring():
            raise TypeError('first input must be in the function ring')
        if x not in self._base_ring:
            raise TypeError('second input must be in the field acted upon')
        return self._drinfeld_module(pol)(x)

    def _latex_(self):
        r"""
        Return a LaTeX representation of the action.

        OUTPUT: a string

        EXAMPLES::

            sage: Fq.<z2> = GF(11)
            sage: FqX.<X> = Fq[]
            sage: K.<z> = Fq.extension(2)
            sage: phi = DrinfeldModule(FqX, [z, 0, 0, 1])
            sage: action = phi.action()
            sage: latex(action)
            \text{Action{ }on{ }}\Bold{F}_{11^{2}}\text{{ }induced{ }by{ }}\text{Drinfeld{ }module{ }defined{ }by{ }} X \mapsto t^{3} + z\text{{ }over{ }base{ }}\Bold{F}_{11^{2}}
        """
        return f'\\text{{Action{{ }}on{{ }}}}' \
               f'{latex(self._base_ring)}\\text{{{{ }}' \
               f'induced{{ }}by{{ }}}}{latex(self._drinfeld_module)}'

    def _repr_(self):
        r"""
        Return a string representation of the action.

        OUTPUT: a string

        EXAMPLES::

            sage: Fq.<z2> = GF(11)
            sage: FqX.<X> = Fq[]
            sage: K.<z> = Fq.extension(2)
            sage: phi = DrinfeldModule(FqX, [z, 0, 0, 1])
            sage: action = phi.action()
            sage: action
            Action on Finite Field in z of size 11^2 over its base induced by Drinfeld module defined by X |--> t^3 + z over base Finite Field in z of size 11^2 over its base
        """
        return f'Action on {self._base_ring} induced by ' \
               f'{self._drinfeld_module}'

    def drinfeld_module(self):
        r"""
        Return the Drinfeld module defining to the action.

        OUTPUT: a Drinfeld module

        EXAMPLES::

            sage: Fq.<z2> = GF(11)
            sage: FqX.<X> = Fq[]
            sage: K.<z> = Fq.extension(2)
            sage: phi = DrinfeldModule(FqX, [z, 0, 0, 1])
            sage: action = phi.action()
            sage: action.drinfeld_module() is phi
            True
        """
        return self._drinfeld_module
