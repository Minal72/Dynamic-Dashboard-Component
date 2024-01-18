# Dynamic-Dashboard-Component

Overview
This Lightning Web Component (LWC) provides a dynamic dashboard to display objects and their records. The component leverages custom metadata (Dashboard_Settings__mdt) to store information about the objects and their related fields to be shown on the dashboard. The backend functionality is handled by the Apex class (DashboardComponentController), which retrieves the metadata records and communicates with the LWC to display the information.

Features
Dynamic Grid Layout: The grid boxes on the UI adjust dynamically to fit three at a time on each row, providing a responsive and visually appealing dashboard.

Configurable Filters: Users can apply six different filters to refine and focus on specific data sets, enhancing the flexibility of the dashboard.The total count of records is also displayed.

Sortable Fields: Each field of the displayed object supports data sorting, similar to the functionality available on the standard records page in Salesforce.

Usage
Install Salesforce CLI
Install the Salesforce Extension pack in your VS Code
Ensure that the necessary custom metadata records (Dashboard_Settings__mdt) are configured with the desired object and field information.
Use the provided Apex class (DashboardComponentController) to pull the metadata records and interact with the Lightning Web Component(dashboardComponentLWC).

Issues and Contributions
This project may have bugs, and your feedback is valuable. If you encounter any issues or have suggestions for improvement, please feel free to reach out. Contact me via email at minal.patil755@gmail.com.

Getting Started
To get started with this Lightning Web Component, follow the steps outlined in the "Usage" section. Feel free to customize and extend the component based on your specific requirements.

 
