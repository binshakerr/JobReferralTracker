import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("Job Referral Tracker")
                .font(.title2)
                .navigationTitle("Referrals")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
