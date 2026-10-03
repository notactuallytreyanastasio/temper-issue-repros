// Calls Gauge::bump from 8 threads, 100,000 times each, then prints the
// fields. The program hangs if bump deadlocks.
fn main() {
    two_reads::init(None).unwrap();
    let g = two_reads::Gauge::new();
    let threads: Vec<_> = (0..8)
        .map(|_| {
            let g = g.clone();
            std::thread::spawn(move || {
                for _ in 0..100_000 {
                    g.bump();
                }
            })
        })
        .collect();
    for t in threads {
        t.join().unwrap();
    }
    println!("done: inside={} maxInside={}", g.inside(), g.max_inside());
}
