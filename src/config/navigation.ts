import type { NavLink } from "../types";

// Top navigation. Set isActive to false to hide a link.
export const NAV_LINKS: NavLink[] = [
    { href: "/", label: "About", isActive: true },
    { href: "/publications", label: "Research", isActive: true },
    { href: "/projects", label: "Projects", isActive: true },
    // { href: "/cv", label: "CV", isActive: true },
    { href: "/talks", label: "Talks", isActive: false },
    { href: "/teaching", label: "Teaching", isActive: false },
    { href: "/posts", label: "Blog", isActive: false },
    { href: "/tags", label: "Tags", isActive: false },
];
