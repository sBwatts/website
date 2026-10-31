import type { PagesConfig } from "../types";

// Section titles and subtitles. Set isActive to false to turn a whole section off.
export const PAGES: PagesConfig = {
    home: {
        title: "About me",
        subtitle: "",
        isActive: true,
    },
    blog: {
        title: "Blog",
        subtitle: "",
        isActive: false,
    },
    publications: {
        
        title: "Scholarly works",
        subtitle: "",
        isActive: true,
    },
    talks: {
        title: "Talks & Presentations",
        subtitle: "Invited talks, conference presentations, and public lectures.",
        isActive: false,
    },
    projects: {
        title: "Projects",
        subtitle: "[Under construction.]",
        isActive: true,
    },
    teaching: {
        title: "Teaching",
        subtitle: "Courses taught and educational materials.",
        isActive: false,
    },
    tags: {
        title: "Tags",
        subtitle: "Explore content by topic.",
        isActive: false,
    },
    cv: {
        title: "Curriculum Vitae",
        subtitle: "Academic and professional history.",
        isActive: true,
    },
};
