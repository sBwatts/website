import type { SocialLink } from "../types";

// Links shown in the sidebar and footer. Set isActive to true and fill in href to show one.
export const SOCIALS: SocialLink[] = [
    {
        name: "Github",
        href: "https://github.com/sBwatts",
        linkTitle: "Seth Watts on Github",
        isActive: true,
    },
    {
        name: "Mail",
        href: "sbwatts@txstate.edu",
        linkTitle: "Send an email to Seth Watts",
        isActive: true,
    },
    {
        name: "ORCID",
        href: "https://orcid.org/0000-0002-5108-9055",
        linkTitle: "Seth Watts on ORCID",
        isActive: false,
    },
    {
        name: "Google Scholar",
        href: "https://scholar.google.com/citations?user=_zgKKS0AAAAJ&hl=en&oi=ao",
        linkTitle: "Seth Watts on Google Scholar",
        isActive: true,
    },
];

export const SOCIAL_ICONS: Record<string, string> = {
    Github: "Github",
    Mail: "Mail",
    Linkedin: "LinkedIn",
    "Google Scholar": "GoogleScholar",
    ORCID: "ORCID",
    RSS: "RSS",
};
