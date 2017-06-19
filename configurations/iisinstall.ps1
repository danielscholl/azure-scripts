configuration Main {
  node "localhost"
  {
    WindowsFeature IIS
    {
      Ensure = "Present"
      Name = "Web-Server"
    }
  }
}
