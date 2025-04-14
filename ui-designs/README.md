# Temptation Destroyer UI Design System

This folder contains the modular UI design system for Temptation Destroyer, organized to improve maintainability, enable dark mode, and follow separation of concerns principles.

## Folder Structure

```
/ui-designs/
├── components/         # Reusable UI components
├── screens/            # Complete screen layouts
├── shared/             # Shared resources (head, styles)
├── index.html          # Main design system viewer (SSI version)
└── index-js.html       # Alternative viewer using JavaScript imports
```

## Components Organization

The design system is broken down into the following components:

### Shared Resources
- `shared/head.html` - Meta tags, title, and Tailwind configuration
- `shared/styles.html` - Global styles and dark mode styles

### UI Components
- `components/dark-mode-toggle.html` - Dark mode toggle button
- `components/header.html` - Header with navigation
- `components/color-palette.html` - Color palette display
- `components/typography.html` - Typography styles
- `components/buttons.html` - Button variants
- `components/input-fields.html` - Form input components
- `components/achievement-card.html` - Achievement system components

### Screen Components
- `screens/auth-screen.html` - Authentication screen
- `screens/dashboard-screen.html` - Main dashboard
- `screens/journal-entry-screen.html` - Journal entry form
- `screens/statistics-screen.html` - Statistics display
- `screens/onboarding-triggers.html` - Onboarding (triggers)
- `screens/onboarding-aspirations.html` - Onboarding (aspirations)
- `screens/onboarding-hobbies.html` - Onboarding (hobbies)
- `screens/ai-response.html` - AI guidance response
- `screens/emergency-response.html` - Emergency response tool

## How to Use

### Viewing the Design System

There are two ways to view the complete design system:

1. **Server-Side Includes (Recommended)**: Open the `index.html` file in a web server that supports server-side includes (Apache with SSI enabled, Nginx with SSI module, etc.)

2. **JavaScript Imports**: For servers that don't support SSI, use the `index-js.html` file which loads components using JavaScript fetch API.

### Adding New Components

1. Create a new HTML file in the appropriate folder:
   - For reusable UI components: `/components/`
   - For complete screens: `/screens/`
   - For shared resources: `/shared/`

2. Follow the existing component structure with appropriate comments

3. Add the component to the design system:
   - For `index.html` (SSI version):
     ```html
     <!--#include file="path/to/component.html" -->
     ```
   
   - For `index-js.html` (JavaScript version):
     1. Add a container div with an ID:
        ```html
        <div id="my-component-container"></div>
        ```
     2. Add the loading code in the script section:
        ```javascript
        loadComponent('my-component-container', 'path/to/component.html');
        ```

### Dark Mode Support

All components support dark mode through Tailwind's dark mode classes. The dark mode toggle in the top-right corner can be used to switch between light and dark themes. 

Dark mode styles use the pattern:
```html
<div class="bg-white dark:bg-gray-800">
  <p class="text-gray-800 dark:text-gray-200">Content</p>
</div>
```

## Development Notes

- Each component is self-contained and can be used independently
- Color variables are defined in the Tailwind config in `shared/head.html`
- Components use responsive design for different screen sizes
- Dark mode is implemented using Tailwind's `dark:` variant
- Two import methods are supported:
  - Server-side includes (SSI) for server environments
  - JavaScript dynamic imports for static file servers 