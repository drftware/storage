"""Roll-up door curtain kinematics.

The curtain is a chain of rigid slats, one corrugation rib each, hinged at the rib valleys.
One number drives it: `rise`, how far the curtain's bottom edge has lifted (studs).

Everything is solved in the door's 2D side plane:
    z = outward (toward the hallway), y = up
with the origin at the bottom centre of the opening, on the curtain plane. The curtain hangs
in the guides along z = 0 up to the guide top G, runs straight to a tangent point T on the
coil, then winds inward along an Archimedean spiral to its anchor on the drum.

`src/shared/StorageUnit/Curtain.luau` is a line-for-line port; `tests/curtain.spec.luau`
checks the two agree on the numbers this file prints with `--selftest`.
"""

import math


class Curtain:
    def __init__(self, *, pitch, count, bottom_closed, guide_top, drum_z, drum_y, r0, wrap):
        self.pitch = pitch              # slat height along the curtain (one rib)
        self.count = count              # number of slats
        self.length = pitch * count     # curtain length, bottom edge to drum anchor
        self.bottom_closed = bottom_closed  # y of the curtain's bottom edge, door shut
        self.guide_top = guide_top      # y where the curtain leaves the guides (z = 0)
        self.cz, self.cy = drum_z, drum_y   # drum axis
        self.r0 = r0                    # drum pipe radius
        self.k = wrap / (2.0 * math.pi)  # coil radius gained per radian wound

    # --- the spiral -------------------------------------------------------------------
    def arc(self, phi):
        """Curtain length wound from the anchor through angle phi."""
        return self.r0 * phi + 0.5 * self.k * phi * phi

    def arc_inv(self, s):
        s = max(s, 0.0)
        return (-self.r0 + math.sqrt(self.r0 * self.r0 + 2.0 * self.k * s)) / self.k

    def radius(self, phi):
        return self.r0 + self.k * phi

    def _tangent(self, R):
        """Tangent point on the coil (radius R) for the line from the guide top.

        Returns (theta, length): the polar angle of T about the drum axis and |T - G|.
        The curtain arrives at T heading counter-clockwise (front, over the top, to the back).
        """
        dz, dy = 0.0 - self.cz, self.guide_top - self.cy
        D = math.hypot(dz, dy)
        a = math.acos(min(1.0, R / D))
        base = math.atan2(dy, dz)
        for theta in (base + a, base - a):
            tz = self.cz + R * math.cos(theta)
            ty = self.cy + R * math.sin(theta)
            # counter-clockwise tangent at theta is (-sin, cos)
            if (tz - 0.0) * -math.sin(theta) + (ty - self.guide_top) * math.cos(theta) > 0.0:
                return theta, math.sqrt(max(D * D - R * R, 0.0))
        raise ValueError("guide top is inside the coil")

    def solve(self, rise, phi_guess=None):
        """State for a given rise: (rise, phi, theta_T, ell)."""
        hanging = self.guide_top - (self.bottom_closed + rise)
        target = self.length - hanging  # curtain beyond the guide top
        phi = phi_guess if phi_guess is not None else self.arc_inv(target)
        for _ in range(12):
            R = self.radius(phi)
            _, ell = self._tangent(R)
            f = self.arc(phi) + ell - target
            df = R - (R * self.k) / max(ell, 1e-6)
            step = f / df
            phi -= step
            if abs(step) < 1e-9:
                break
        theta, ell = self._tangent(self.radius(phi))
        return (rise, phi, theta, ell)

    def point(self, u, state):
        """Point on the curtain at distance u from its bottom edge: (z, y)."""
        rise, phi, theta_t, ell = state
        bottom = self.bottom_closed + rise
        hanging = self.guide_top - bottom
        if u <= hanging:
            return (0.0, bottom + u)
        u -= hanging
        R = self.radius(phi)
        tz = self.cz + R * math.cos(theta_t)
        ty = self.cy + R * math.sin(theta_t)
        if u <= ell:
            f = u / ell if ell > 1e-9 else 0.0
            return (tz * f, self.guide_top + (ty - self.guide_top) * f)
        w = u - ell
        p = self.arc_inv(self.arc(phi) - w)
        th = theta_t + (phi - p)
        r = self.radius(p)
        return (self.cz + r * math.cos(th), self.cy + r * math.sin(th))

    def slats(self, rise, phi_guess=None):
        """Every slat's hinge-chord frame: list of (mid_z, mid_y, dir_z, dir_y), bottom first.

        dir is the unit vector up the curtain; the slat's outward normal is (dir_y, -dir_z).
        """
        state = self.solve(rise, phi_guess)
        out = []
        a = self.point(0.0, state)
        for i in range(self.count):
            b = self.point((i + 1) * self.pitch, state)
            dz, dy = b[0] - a[0], b[1] - a[1]
            n = math.hypot(dz, dy) or 1.0
            out.append(((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5, dz / n, dy / n))
            a = b
        return out, state

    def drum_angle(self, state):
        """Drum rotation (radians, counter-clockwise in z-y) relative to the shut door.

        The anchor sits at polar angle theta_T + phi, and it is welded to the drum.
        """
        return (state[2] + state[1]) - self._anchor_closed

    def prime(self):
        st = self.solve(0.0)
        self._anchor_closed = st[2] + st[1]
        return self


def selftest():
    c = Curtain(pitch=0.3, count=38, bottom_closed=0.36, guide_top=8.3,
                drum_z=-0.55, drum_y=8.95, r0=0.28, wrap=0.075).prime()
    for rise in (0.0, 1.15, 4.0, 7.65):
        frames, st = c.slats(rise)
        gaps = []
        prev = c.point(0.0, st)
        for i in range(c.count):
            nxt = c.point((i + 1) * c.pitch, st)
            gaps.append(math.hypot(nxt[0] - prev[0], nxt[1] - prev[1]))
            prev = nxt
        print(f"rise={rise:5.2f} phi={st[1]:8.4f} theta={st[2]:8.4f} ell={st[3]:7.4f} "
              f"R={c.radius(st[1]):6.4f} turns={st[1] / (2 * math.pi):5.2f} "
              f"chord min/max={min(gaps):.4f}/{max(gaps):.4f} "
              f"slat0=({frames[0][0]:.4f},{frames[0][1]:.4f}) slat37=({frames[-1][0]:.4f},{frames[-1][1]:.4f})")


if __name__ == "__main__":
    selftest()
